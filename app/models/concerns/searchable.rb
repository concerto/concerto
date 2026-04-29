# frozen_string_literal: true

# Searchable wires a model into the cross-model FTS5 corpus (see
# Search::Corpus). Including classes implement `searchable_data` to control
# what `name`/`body` text is indexed, and may override `searchable?` to gate
# whether a row should appear in the corpus at all (e.g. unapproved Content).
module Searchable
  extend ActiveSupport::Concern

  included do
    after_commit :reindex_search_corpus, on: [ :create, :update ]
    after_commit :remove_from_search_corpus, on: :destroy

    Search::Corpus.register(self)
  end

  def searchable?
    true
  end

  def searchable_data
    { name: try(:name), body: nil }
  end

  private

  def reindex_search_corpus
    if searchable?
      Search::Corpus.upsert(self, searchable_data)
    else
      Search::Corpus.delete(self)
    end
  end

  def remove_from_search_corpus
    Search::Corpus.delete(self)
  end
end
