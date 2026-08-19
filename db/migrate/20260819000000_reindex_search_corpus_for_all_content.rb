# Content used to be indexed only once it had an approved submission, so
# unsubmitted/pending/rejected uploads were unsearchable even for their own
# owner (#1958). Visibility is now decided by Pundit at query time, so the
# corpus indexes everything — rebuild it to pick up the previously skipped rows.
class ReindexSearchCorpusForAllContent < ActiveRecord::Migration[8.1]
  def up
    Rails.application.eager_load!
    Search::Corpus.rebuild!
  end

  def down
    # The corpus is a derived cache; nothing to undo.
  end
end
