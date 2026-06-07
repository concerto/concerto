require "application_system_test_case"

class ContentsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit contents_url
    assert_selector "h1", text: "Active Content"

    # This test depends on the anonymous policy scope (only approved content is
    # shown to a signed-out user). The "New Content" button renders only for a
    # signed-in user, so its absence confirms the session is truly anonymous and
    # guards against an authenticated session leaking in from another test, which
    # would otherwise inflate the image count -- see #1834.
    assert_no_link "New Content"

    assert_selector "#contents img", count: anonymous_image_count(Content.active)
    assert_selector "#contents div", text: rich_texts(:e2e_ticker_1).text
  end

  test "viewing expired content" do
    visit contents_url(scope: "expired")
    assert_selector "h1", text: "Expired Content"

    assert_no_link "New Content"

    assert_selector "#contents img", count: anonymous_image_count(Content.expired)
    assert_selector "#contents div", text: rich_texts(:plain_richtext).text
  end

  test "should link to create content" do
    sign_in users(:admin)
    visit contents_url
    click_on "New Content", match: :first

    assert_selector "h1", text: "Add Content"

    has_link? "Add Graphic", href: new_graphic_path
    has_link? "Add Text / HTML", href: new_rich_text_path
    has_link? "Add Video", href: new_video_path
  end

  private

  # Mirrors what the grid renders for an anonymous viewer: one <img> per piece
  # of content visible to a signed-out user (approved only) that actually
  # produces an image tag -- Graphics with a variable attachment and all Videos.
  # Deriving the expected count the same way the page builds it keeps this test
  # consistent regardless of who (if anyone) is signed in.
  def anonymous_image_count(scope)
    visible = ContentPolicy::Scope.new(nil, scope).resolve
    visible.count do |content|
      case content
      when Graphic then content.image.attached? && content.image.variable?
      when Video   then true
      else              false
      end
    end
  end
end
