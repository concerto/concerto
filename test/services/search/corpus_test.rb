require "test_helper"

class Search::CorpusTest < ActiveSupport::TestCase
  setup do
    Search::Corpus.rebuild!
  end

  test "registry includes Content and Feed" do
    assert_includes Search::Corpus.registry, Content
    assert_includes Search::Corpus.registry, Feed
  end

  test "register is idempotent" do
    before = Search::Corpus.registry.size
    Search::Corpus.register(Content)
    assert_equal before, Search::Corpus.registry.size
  end

  test "resolve returns the registered class for known type" do
    assert_equal Content, Search::Corpus.resolve("Content")
    assert_equal Feed, Search::Corpus.resolve("Feed")
  end

  test "resolve returns nil for unknown / unregistered type" do
    assert_nil Search::Corpus.resolve("User")
    assert_nil Search::Corpus.resolve("Object")
  end

  test "upsert inserts a row keyed on base class name" do
    rich_text = rich_texts(:plain_richtext)
    Search::Corpus.delete(rich_text)

    Search::Corpus.upsert(rich_text, { name: "test name", body: "test body" })

    rows = ActiveRecord::Base.connection.exec_query(
      "SELECT searchable_type, searchable_id, name, body FROM search_corpus WHERE searchable_id = #{rich_text.id} AND searchable_type = 'Content'"
    ).rows
    assert_equal 1, rows.size
    assert_equal "Content", rows.first[0]
    assert_equal rich_text.id, rows.first[1]
    assert_equal "test name", rows.first[2]
    assert_equal "test body", rows.first[3]
  end

  test "upsert replaces an existing row instead of duplicating" do
    rich_text = rich_texts(:plain_richtext)
    Search::Corpus.upsert(rich_text, { name: "first", body: "" })
    Search::Corpus.upsert(rich_text, { name: "second", body: "" })

    count = ActiveRecord::Base.connection.select_value(
      "SELECT COUNT(*) FROM search_corpus WHERE searchable_type = 'Content' AND searchable_id = #{rich_text.id}"
    )
    assert_equal 1, count
  end

  test "delete removes the row" do
    rich_text = rich_texts(:plain_richtext)
    Search::Corpus.upsert(rich_text, { name: "x", body: "" })
    Search::Corpus.delete(rich_text)

    count = ActiveRecord::Base.connection.select_value(
      "SELECT COUNT(*) FROM search_corpus WHERE searchable_type = 'Content' AND searchable_id = #{rich_text.id}"
    )
    assert_equal 0, count
  end

  test "rebuild! populates rows for all registered models with searchable records" do
    expected = Content.find_each.count(&:searchable?) + Feed.count

    Search::Corpus.rebuild!

    assert_equal expected, Search::Corpus.count
    assert_equal Feed.count, Search::Corpus.count_for(Feed)
  end

  test "rebuild! rolls back on failure leaving prior state intact" do
    Search::Corpus.rebuild!
    before = Search::Corpus.count

    Content.stub :find_each, ->(*) { raise "boom" } do
      assert_raises(RuntimeError) { Search::Corpus.rebuild! }
    end

    assert_equal before, Search::Corpus.count
  end
end
