require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    Search::Corpus.rebuild!
  end

  test "renders empty page for blank query" do
    get search_url
    assert_response :success
    assert_select "input[name='q']"
  end

  test "renders results for matching query" do
    rss = rss_feeds(:yahoo_rssfeed)
    get search_url, params: { q: "yahoo" }
    assert_response :success
    assert_select "a[href='#{rss_feed_path(rss)}']"
  end

  test "renders empty state when no matches" do
    get search_url, params: { q: "completelyabsentterm" }
    assert_response :success
    assert_select "h3", text: "No matches"
  end

  test "does not error on adversarial input" do
    get search_url, params: { q: %("; DROP TABLE search_corpus; --) }
    assert_response :success
  end
end
