require "test_helper"

class GraphicTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @graphic = graphics(:one)
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

  test "fit_score is zero for a position outside the aspect-ratio window" do
    assert_equal 0.0, @graphic.fit_score(positions(:two_ticker))
  end

  test "fit_score scores a closer aspect ratio higher" do
    # The graphic's aspect ratio (~1.33) sits closer to the main position
    # (~1.31, on the template's real 16:9 canvas) than to the sidebar (~0.73),
    # so it should score higher there even though both are inside the
    # tolerance window.
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
