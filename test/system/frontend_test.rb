require "application_system_test_case"

class FrontendTest < ApplicationSystemTestCase
  setup do
    analyze_graphics

    @screen = screens(:e2e)
  end

  test "frontend runs" do
    visit frontend_player_url(@screen)

    text_content = [ rich_texts(:e2e_ticker_1), rich_texts(:e2e_ticker_2) ]
    graphic_content = [ graphics(:e2e_graphic_1), graphics(:e2e_graphic_2) ]

    loop_count = 0

    while loop_count < 30 && (text_content.length > 0 || graphic_content.length > 0)
      text_content.delete_if do |item|
        page.has_text?(item.text)
      end

      graphic_content.delete_if do |item|
        page.html.include? rails_blob_path(item.image, only_path: true)
      end

      sleep 0.5

      loop_count += 1
    end

    assert text_content.empty?, "#{text_content.length} pieces of text content not shown:\n #{text_content.to_yaml}"
    assert graphic_content.empty?, "#{graphic_content.length} graphics not shown:\n #{graphic_content.to_yaml}"
  end
end
