# frozen_string_literal: true

# AR-backed view of the FTS5 `search_corpus` virtual table. Used by
# Search::Corpus for row-level CRUD and by Search for query construction.
# FTS5 exposes the table name itself and `rank` as magic columns; we hide
# them from AR introspection so inserts and ordering reference only the
# real columns. The table has no AR-style id PK — rowid is implicit and we
# never need to fetch it back, so leave primary_key unset.
class SearchRow < ApplicationRecord
  self.table_name = "search_corpus"
  self.primary_key = "rowid"
  self.ignored_columns = %w[search_corpus rank]
end
