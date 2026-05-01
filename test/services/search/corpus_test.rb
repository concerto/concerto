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

    rows = SearchRow.where(searchable_type: "Content", searchable_id: rich_text.id)
    assert_equal 1, rows.count
    row = rows.first
    assert_equal "Content", row.searchable_type
    assert_equal rich_text.id, row.searchable_id
    assert_equal "test name", row.name
    assert_equal "test body", row.body
  end

  test "upsert replaces an existing row instead of duplicating" do
    rich_text = rich_texts(:plain_richtext)
    Search::Corpus.upsert(rich_text, { name: "first", body: "" })
    Search::Corpus.upsert(rich_text, { name: "second", body: "" })

    count = SearchRow.where(searchable_type: "Content", searchable_id: rich_text.id).count
    assert_equal 1, count
  end

  test "delete removes the row" do
    rich_text = rich_texts(:plain_richtext)
    Search::Corpus.upsert(rich_text, { name: "x", body: "" })
    Search::Corpus.delete(rich_text)

    count = SearchRow.where(searchable_type: "Content", searchable_id: rich_text.id).count
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
