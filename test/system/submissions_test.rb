require "application_system_test_case"

class SubmissionsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
  end

  test "visiting the index" do
    visit submissions_url
    assert_selector "h1", text: "Moderation Queue"
  end
end
