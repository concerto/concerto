class CreateSearchCorpus < ActiveRecord::Migration[8.1]
  def change
    create_virtual_table :search_corpus, :fts5, [
      "searchable_type UNINDEXED",
      "searchable_id UNINDEXED",
      "name",
      "body",
      "tokenize='porter unicode61'"
    ]
  end
end
