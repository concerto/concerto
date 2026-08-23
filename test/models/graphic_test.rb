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
  TIME = Position.new(left: 0.024, top: 0.885, right: 0.18, bottom: 0.974, template: CANVAS)

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

  test "fit_score is zero where the graphic could only render as a thumbnail" do
    assert_equal 0.0, @graphic.fit_score(positions(:two_ticker))
  end

  test "a flyer never renders in a ticker, whichever way up it is" do
    # A ticker can only show a page-shaped graphic about a tenth of the size
    # the screen could — a 2.4" sliver on a 48" TV. Nothing on it is readable,
    # so the ticker is not a candidate at all (issue #1926).
    assert_equal 0.0, flyer(:portrait).fit_score(TICKER)
    assert_equal 0.0, flyer(:landscape).fit_score(TICKER)
  end

  test "a flyer renders comfortably in main either way up" do
    assert flyer(:portrait).fit_score(MAIN) > 0.5
    assert flyer(:landscape).fit_score(MAIN) > 0.5
  end

  test "the sidebar suits a portrait flyer and a landscape one prefers main" do
    # The sidebar is a tall narrow rail: it shows a portrait page nearly
    # whole, but has to shrink a landscape one to fit its width. Landscape
    # still renders there — it is only outranked.
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
  end

  test "a banner too square for the ticker falls back to main, not the clock" do
    # 758x307, the graphic that did not render in the #1926 report. Scored on
    # shape alone it matched the clock box (~3:1) far better than main, so it
    # was routed to a slot that renders it at an eighth of its usable size.
    # Size is now part of the score, so the clock is disqualified outright.
    banner = sized(758, 307)

    assert_equal 0.0, banner.fit_score(TIME)
    assert banner.fit_score(MAIN) > banner.fit_score(SIDEBAR)
    assert banner.fit_score(MAIN).positive?
  end

  test "a small position is disqualified however well its shape matches" do
    # The clock box is the right shape for a 3:1 banner and still far too
    # small for it; shape alone must not be able to win a position.
    banner = sized(758, 307)

    assert_in_delta banner.image.metadata[:width].fdiv(banner.image.metadata[:height]),
      TIME.aspect_ratio, 0.7, "the clock box really is a close shape match"
    assert_equal 0.0, banner.fit_score(TIME)
  end

  test "the veto reaches strips and clock boxes, not real content areas" do
    # Deliberately extreme-only: a badly-shaped graphic still renders in a
    # sidebar, because withholding content is worse than rendering it
    # awkwardly. Only a position that shrinks it to a sliver is ruled out.
    banner = sized(1331, 99)

    # A 13:1 banner in a 0.67:1 rail is the worst shape mismatch the stock
    # templates can produce, and it still renders.
    assert banner.fit_score(SIDEBAR).positive?
    assert flyer(:landscape).fit_score(SIDEBAR).positive?

    # The clock box is what "extreme" looks like. A banner shaped roughly like
    # it survives — the veto asks about size, not shape, and never claims a
    # position is wrong for content it can actually show — but it scores last
    # by two orders of magnitude and can only ever win by being the only
    # option. Page-shaped content there is ruled out outright.
    assert banner.fit_score(TIME) < banner.fit_score(TICKER) / 50
    assert_equal 0.0, flyer(:portrait).fit_score(TIME)
  end

  test "the score ignores resolution entirely" do
    # fit_score reads shape, never pixel count, so uploading at 4K can neither
    # trigger the veto nor rescue content from it. Deliberate: the veto asks
    # how large the image renders on the screen, not how much detail it has.
    [ MAIN, TICKER, SIDEBAR, TIME ].each do |position|
      assert_equal sized(3840, 2160).fit_score(position),
        sized(160, 90).fit_score(position),
        "a 4K graphic and a thumbnail of the same shape must score the same"
    end
  end

  test "letterboxing costs but never disqualifies" do
    # A wide banner in the tall sidebar wastes almost all of the box, yet what
    # renders is whole and legible, so it stays a candidate — the same rule
    # that lets RichText render awkwardly rather than vanish.
    assert sized(1331, 99).fit_score(SIDEBAR).positive?
  end

  test "fit_score scores a closer aspect ratio higher" do
    # The graphic's aspect ratio (~1.33) sits closer to the main position
    # (~1.31, on the template's real 16:9 canvas) than to the sidebar (~0.73),
    # so it should score higher there even though both render it large
    # enough to be a candidate.
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

  test "an unanalyzed graphic falls back to the neutral base score" do
    graphic = Graphic.new(name: "Fresh", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("one.jpg").open, filename: "one.jpg", content_type: "image/jpeg")

    assert_equal 1.0, graphic.fit_score(TICKER)
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
