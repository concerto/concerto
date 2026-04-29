require "test_helper"

class SearchableTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @feed = feeds(:one)
    Search::Corpus.rebuild!
  end

  test "creating a Content with no submissions does not insert into corpus" do
    content = nil
    assert_no_difference -> { Search::Corpus.count } do
      content = RichText.create!(name: "Lonely", text: "alone", user: @user, duration: 5, config: { render_as: "plaintext" })
    end
    refute content.searchable?
  end

  test "creating a Content with an auto-approved submission inserts into corpus" do
    content = RichText.create!(name: "Auto Approved", text: "hello", user: @user, duration: 5, config: { render_as: "plaintext" })

    assert_difference -> { Search::Corpus.count_for(Content) }, 1 do
      Submission.create!(content: content, feed: @feed)
    end
  end

  test "destroying a Content removes its corpus row" do
    content = rich_texts(:plain_richtext)
    Search::Corpus.upsert(content, content.searchable_data)

    assert_difference -> { Search::Corpus.count_for(Content) }, -1 do
      content.destroy!
    end
  end

  test "creating a Feed inserts into corpus" do
    assert_difference -> { Search::Corpus.count_for(Feed) }, 1 do
      Feed.create!(name: "Brand New", description: "for tests", group: groups(:feed_one_owners))
    end
  end

  test "updating a Feed name updates its corpus row" do
    feed = feeds(:one)
    feed.update!(name: "Renamed Feed")

    row = ActiveRecord::Base.connection.exec_query(
      "SELECT name FROM search_corpus WHERE searchable_type = 'Feed' AND searchable_id = #{feed.id}"
    ).rows.first
    assert_equal "Renamed Feed", row[0]
  end

  test "Searchable registers including classes once each" do
    # Re-registering an already-registered class is a no-op
    before = Search::Corpus.registry.size
    Search::Corpus.register(Content)
    assert_equal before, Search::Corpus.registry.size

    assert_equal 1, Search::Corpus.registry.count(Content)
    assert_equal 1, Search::Corpus.registry.count(Feed)
  end
end
