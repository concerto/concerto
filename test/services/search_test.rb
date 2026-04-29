require "test_helper"

class SearchTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    Search::Corpus.rebuild!
  end

  test "build_match returns nil for blank input" do
    assert_nil Search.build_match("")
    assert_nil Search.build_match(nil)
    assert_nil Search.build_match("   ")
  end

  test "build_match wraps tokens in quotes with prefix wildcard" do
    assert_equal %("hello"*), Search.build_match("hello")
    assert_equal %("hello"* "world"*), Search.build_match("hello world")
  end

  test "build_match strips FTS5 syntax characters out" do
    # Quotes, asterisks, NEAR, OR/AND/NOT — none should leak through.
    assert_equal %("foo"* "bar"*), Search.build_match(%("foo* bar))
    assert_equal %("OR"* "x"*), Search.build_match("OR x") # OR becomes a regular token, not an operator
    assert_equal %("foo"* "bar"*), Search.build_match("foo:bar") # colons split
    assert_equal %("foo"*), Search.build_match("(foo)")
    assert_equal %("foo"*), Search.build_match("foo+++")
  end

  test "build_match handles unicode tokens" do
    # Non-ASCII word characters survive (\W is Unicode-aware in Ruby Onigmo)
    refute_nil Search.build_match("café")
  end

  test "matching_ids returns ids for matching Feed name" do
    rss = rss_feeds(:yahoo_rssfeed)
    ids = Search.matching_ids("yahoo", Feed)
    assert_includes ids, rss.id
  end

  test "matching_ids returns ids for matching Content via base class" do
    video = Video.create!(name: "Sample Vid", config: { url: "https://www.youtube.com/watch?v=test" }, user: @admin, duration: 30)
    Submission.create!(content: video, feed: feeds(:one)) # auto-approves (admin is in feed_one_owners)

    ids = Search.matching_ids("youtube", Content)
    assert_includes ids, video.id
  end

  test "matching_ids returns empty for blank query" do
    assert_equal [], Search.matching_ids("", Content)
    assert_equal [], Search.matching_ids(nil, Content)
  end

  test "matching_ids ignores adversarial FTS5 syntax" do
    assert_nothing_raised { Search.matching_ids('"); DROP TABLE', Content) }
    assert_nothing_raised { Search.matching_ids("*", Content) }
    assert_nothing_raised { Search.matching_ids("NEAR(foo, 5)", Content) }
  end

  test "call returns flat array filtered through policy_scope" do
    rss = rss_feeds(:yahoo_rssfeed)
    results = Search.call("yahoo", user: @admin)
    assert_includes results.map(&:id), rss.id
    assert(results.all? { |r| r.is_a?(Content) || r.is_a?(Feed) })
  end

  test "call returns empty array for blank query" do
    assert_equal [], Search.call("", user: @admin)
  end

  test "call respects policy_scope — unapproved Content not returned even when in corpus" do
    # Inject an unapproved Content into the corpus directly to test post-fetch
    # filtering (a real-world way this happens: someone tampers with the index,
    # or moderation state changes after a query).
    unapproved = RichText.create!(name: "TopSecret", text: "matchterm", user: @admin, duration: 5, config: { render_as: "plaintext" })
    Search::Corpus.upsert(unapproved, unapproved.searchable_data)

    results = Search.call("matchterm", user: @admin)
    refute_includes results.map(&:id), unapproved.id
  end
end
