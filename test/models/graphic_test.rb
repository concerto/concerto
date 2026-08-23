require "test_helper"

class GraphicTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # The Blue Swoosh template from db/seeds.rb, the geometry the fit model was
  # calibrated against (issues #1906/#1926). Fractional coordinates only
  # describe a shape alongside the canvas they sit on, so these carry one: an
  # image-less Template reports the default 16:9, which Blue Swoosh is.
  CANVAS = Template.new
  MAIN = Position.new(left: 0.025, top: 0.026, right: 0.592, bottom: 0.796, template: CANVAS)
  TICKER = Position.new(left: 0.221, top: 0.885, right: 0.975, bottom: 0.985, template: CANVAS)
  SIDEBAR = Position.new(left: 0.68, top: 0.015, right: 0.98, bottom: 0.811, template: CANVAS)

  setup do
    @graphic = graphics(:one)
  end

  # A graphic of the given pixel dimensions. The bytes never matter — fit_score
  # reads only the analysis metadata — so every one of these points at the same
  # fixture file.
  def sized(width, height)
    graphic = Graphic.new(name: "#{width}x#{height}", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("one.jpg").open, filename: "one.jpg", content_type: "image/jpeg")
    graphic.image.blob.metadata.merge!(width: width, height: height, analyzed: true)
    graphic
  end

  # An 8.5x11 flyer at 300dpi: the shape most likely to be posted to a screen,
  # and the one bamnet spelled out expectations for on #1926.
  def flyer(orientation)
    orientation == :portrait ? sized(2550, 3300) : sized(3300, 2550)
  end

  # A box occupying the given fraction of the screen in each direction.
  def position(width_fraction, height_fraction, aspect: nil)
    height_fraction = width_fraction * CANVAS.aspect_ratio / aspect if aspect
    Position.new(left: 0.0, right: width_fraction, top: 0.0, bottom: height_fraction, template: CANVAS)
  end

  test "has analyzed metadata" do
    assert_equal 4080, @graphic.image.metadata[:width]
    assert_equal 3072, @graphic.image.metadata[:height]
  end

  test "should render images in appropriate fields" do
    assert @graphic.fit_score(positions(:two_graphic)).positive?

    assert_not @graphic.fit_score(positions(:two_ticker)).positive?
  end

  test "is not renderable while the image is still a PDF" do
    assert_not graphics(:pdf_graphic).renderable?
    assert @graphic.renderable?
  end

  test "fit_score is zero where the image would leave the box nearly empty" do
    assert_equal 0.0, @graphic.fit_score(positions(:two_ticker))
  end

  test "position size has no bearing on the score" do
    # The heart of the model: we score how well a graphic fits a position's
    # shape and nothing else. A graphic may be a poster covered in text or a
    # weather icon, and nothing in its metadata says which, so how large it
    # renders is the template author's decision rather than ours.
    photo = sized(1920, 1080)
    sixteen_by_nine = CANVAS.aspect_ratio

    scores = [ 1.0, 0.5, 0.1, 0.02 ].map do |fraction|
      photo.fit_score(position(fraction, nil, aspect: sixteen_by_nine))
    end

    assert_equal [ scores.first ] * 4, scores,
      "a full-screen box and a 2% box are the same shape, so they must score alike"
    assert_in_delta 1.0, scores.first, 1e-9
  end

  test "a small position renders content shaped for it" do
    # A status indicator or weather icon lives in a box far too small for a
    # poster, and must still work. Nothing may disqualify a position for
    # being small (#1926).
    indicator_box = position(0.10, 0.10)

    assert sized(1920, 1080).fit_score(indicator_box).positive?
    assert sized(1000, 1000).fit_score(indicator_box).positive?
    assert sized(600, 800).fit_score(indicator_box).positive?
  end

  test "any position can render a graphic shaped like it" do
    # The guarantee that makes "positions of any size" true rather than
    # merely likely: an image matching a box's proportions always fills it
    # completely, so no threshold can ever reach it.
    [ position(1.0, 1.0), position(0.5, 0.5), position(0.1, 0.1),
      position(0.02, 0.02), position(0.9, 0.03), position(0.03, 0.9) ].each do |box|
      ratio = box.aspect_ratio
      graphic = sized((ratio * 1000).round, 1000)

      assert graphic.fit_score(box).positive?,
        "a #{ratio.round(2)}:1 graphic must render in a #{ratio.round(2)}:1 box"
    end
  end

  test "the score ignores resolution entirely" do
    # fit_score reads shape, never pixel count, so a 4K upload and a
    # thumbnail of the same shape are indistinguishable to it. Deliberate for
    # now: comparing delivered pixels against rendered size is separate work.
    [ MAIN, TICKER, SIDEBAR ].each do |box|
      assert_equal sized(3840, 2160).fit_score(box), sized(160, 90).fit_score(box)
    end
  end

  test "a flyer never renders in a ticker, whichever way up it is" do
    # A page-shaped graphic covers 6% of a ticker strip either way up. That
    # is not a poor fit, it is a mistake (#1926).
    assert_equal 0.0, flyer(:portrait).fit_score(TICKER)
    assert_equal 0.0, flyer(:landscape).fit_score(TICKER)
  end

  test "a flyer renders comfortably in main either way up" do
    assert flyer(:portrait).fit_score(MAIN) > 0.5
    assert flyer(:landscape).fit_score(MAIN) > 0.5
  end

  test "the sidebar suits a portrait flyer and a landscape one prefers main" do
    portrait = flyer(:portrait)
    landscape = flyer(:landscape)

    assert portrait.fit_score(SIDEBAR) > portrait.fit_score(MAIN)
    assert landscape.fit_score(MAIN) > landscape.fit_score(SIDEBAR)
    assert landscape.fit_score(SIDEBAR).positive?, "an awkward fit is still a fit"
  end

  test "a wide banner wins the ticker" do
    # 1331x99, the graphic that rendered correctly in the #1926 report.
    banner = sized(1331, 99)

    assert banner.fit_score(TICKER) > banner.fit_score(MAIN)
    assert banner.fit_score(TICKER) > banner.fit_score(SIDEBAR)
    assert banner.fit_score(TICKER) > 0.5
  end

  test "a banner too square for a ticker is no longer dropped everywhere" do
    # 758x307, the graphic that did not render at all in the #1926 report:
    # more than 2x off the ticker's shape, so the old tolerance window scored
    # it 0.0 and it vanished. It now ranks rather than disappears.
    banner = sized(758, 307)

    assert banner.fit_score(MAIN).positive?
    assert banner.fit_score(SIDEBAR).positive?
    assert banner.fit_score(MAIN) > banner.fit_score(SIDEBAR)
  end

  test "what belongs in the sidebar" do
    # bamnet's read of the stock Blue Swoosh sidebar (#1926): everything up to
    # a 2.5:1 banner looks fine there; a 13:1 banner does not.
    assert flyer(:portrait).fit_score(SIDEBAR).positive?
    assert flyer(:landscape).fit_score(SIDEBAR).positive?
    assert sized(3840, 2160).fit_score(SIDEBAR).positive?
    assert sized(758, 307).fit_score(SIDEBAR).positive?

    assert_equal 0.0, sized(1331, 99).fit_score(SIDEBAR)
  end

  test "wasted space costs, and disqualifies only when the box is left empty" do
    # A moderate mismatch is a penalty: what renders is whole and legible, so
    # it stays a candidate rather than vanishing. A 13:1 banner in a tall rail
    # is a different thing — it covers 5% of the box.
    assert sized(758, 307).fit_score(SIDEBAR).positive?
    assert_equal 0.0, sized(1331, 99).fit_score(SIDEBAR)
  end

  test "an unanalyzed graphic falls back to the neutral base score" do
    graphic = Graphic.new(name: "Fresh", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("one.jpg").open, filename: "one.jpg", content_type: "image/jpeg")

    assert_equal 1.0, graphic.fit_score(TICKER)
  end

  test "fit_score scores a closer aspect ratio higher" do
    # The graphic's aspect ratio (~1.33) sits closer to the main position
    # (~1.31, on the template's real 16:9 canvas) than to the sidebar (~0.73),
    # so it should score higher there even though both cover enough of the
    # box to be candidates.
    main = @graphic.fit_score(positions(:two_graphic))
    sidebar = @graphic.fit_score(positions(:two_sidebar))

    assert main.positive?
    assert sidebar.positive?
    assert main > sidebar, "the closer-matched position should score higher"
  end

  test "renders portrait images in similarly-shaped positions" do
    portrait = graphics(:portrait_graphic)
    # The sidebar is the portrait-shaped position here (~0.73 once corrected
    # for the template's real 16:9 canvas); main is landscape-shaped (~1.31).
    assert portrait.fit_score(positions(:two_sidebar)).positive?
    assert_not portrait.fit_score(positions(:two_ticker)).positive?
  end

  test "supported_content_types includes common web image formats" do
    # Regression: previously this list was frozen at class-load time before
    # ActiveStorage's after_initialize populated variable_content_types, so in
    # production the list collapsed to ["application/pdf"] and every image
    # upload was rejected.
    %w[image/png image/jpeg image/gif image/webp].each do |type|
      assert_includes Graphic.supported_content_types, type
    end
  end

  test "accepts supported image content types" do
    Graphic.supported_content_types.excluding("application/pdf").each do |content_type|
      graphic = Graphic.new(name: "Test", duration: 10, user: users(:admin))
      graphic.image.attach(io: StringIO.new("data"), filename: "test", content_type: content_type)
      graphic.valid?
      assert_empty graphic.errors[:image], "Expected #{content_type} to be valid"
    end
  end

  test "accepts PDF uploads" do
    graphic = Graphic.new(name: "Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("flyer.pdf").open, filename: "flyer.pdf", content_type: "application/pdf")
    graphic.valid?
    assert_empty graphic.errors[:image]
  end

  test "rejects unsupported content types" do
    graphic = Graphic.new(name: "Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: StringIO.new("data"), filename: "test.exe", content_type: "application/octet-stream")
    assert_not graphic.valid?
    assert_match(/type .+ is not supported/, graphic.errors[:image].first)
  end

  test "is not renderable with an unsupported content type" do
    graphic = Graphic.new(name: "Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: StringIO.new("data"), filename: "test.exe", content_type: "application/octet-stream")
    assert_not graphic.renderable?
  end

  test "enqueues conversion job when PDF is attached on create" do
    graphic = Graphic.new(name: "PDF Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("flyer.pdf").open, filename: "flyer.pdf", content_type: "application/pdf")

    assert_enqueued_with(job: ConvertPdfToImageJob) do
      graphic.save!
    end
  end

  test "enqueues conversion job when PDF replaces existing image on update" do
    assert_enqueued_with(job: ConvertPdfToImageJob) do
      @graphic.image.attach(io: file_fixture("flyer.pdf").open, filename: "flyer.pdf", content_type: "application/pdf")
      @graphic.save!
    end
  end

  test "does not enqueue conversion job when a regular image is attached" do
    graphic = Graphic.new(name: "Image Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("one.jpg").open, filename: "one.jpg", content_type: "image/jpeg")

    assert_no_enqueued_jobs(only: ConvertPdfToImageJob) do
      graphic.save!
    end
  end

  test "analysis_stuck? returns false when image is not attached" do
    graphic = Graphic.new(name: "Test", duration: 10, user: users(:admin))
    assert_not graphic.analysis_stuck?
  end

  test "analysis_stuck? returns false when image is freshly attached" do
    graphic = Graphic.new(name: "Image Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("one.jpg").open, filename: "one.jpg", content_type: "image/jpeg")
    graphic.save!
    graphic.image.blob.update!(metadata: graphic.image.blob.metadata.except("analyzed"))
    graphic.image.reload

    assert_not graphic.analysis_stuck?
  end

  test "analysis_stuck? returns true when image attached over threshold ago and not analyzed" do
    graphic = Graphic.new(name: "Image Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("one.jpg").open, filename: "one.jpg", content_type: "image/jpeg")
    graphic.save!
    graphic.image.blob.update!(metadata: graphic.image.blob.metadata.except("analyzed"))
    graphic.image.attachment.update!(created_at: 2.minutes.ago)
    graphic.image.reload

    assert graphic.analysis_stuck?
  end

  test "analysis_stuck? returns false once image is analyzed" do
    graphic = Graphic.new(name: "Image Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("one.jpg").open, filename: "one.jpg", content_type: "image/jpeg")
    graphic.save!
    graphic.image.attachment.update!(created_at: 2.minutes.ago)
    graphic.image.analyze

    assert_not graphic.analysis_stuck?
  end

  test "analysis_stuck? returns false for PDFs awaiting conversion" do
    graphic = Graphic.new(name: "PDF Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("flyer.pdf").open, filename: "flyer.pdf", content_type: "application/pdf")
    graphic.save!
    graphic.image.attachment.update!(created_at: 2.minutes.ago)

    assert_not graphic.analysis_stuck?
  end
end
