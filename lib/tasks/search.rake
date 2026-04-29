# frozen_string_literal: true

namespace :search do
  desc "Rebuild the FTS5 search corpus from all registered models"
  task reindex: :environment do
    # Eager-load so every Searchable model registers itself before we walk the registry.
    Rails.application.eager_load!
    Search::Corpus.rebuild!
    puts "Indexed #{Search::Corpus.count} rows across #{Search::Corpus.registry.size} model(s)."
  end

  desc "Compare source row counts to corpus row counts per model (drift detector)"
  task verify: :environment do
    Rails.application.eager_load!

    drift = false
    Search::Corpus.registry.each do |klass|
      expected = klass.find_each.count(&:searchable?)
      actual = Search::Corpus.count_for(klass)
      status = (expected == actual) ? "ok" : "DRIFT"
      drift = true if expected != actual
      puts "#{klass.name.ljust(20)} expected=#{expected} corpus=#{actual} #{status}"
    end
    abort "Drift detected — run `bin/rails search:reindex`" if drift
  end
end
