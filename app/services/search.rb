# frozen_string_literal: true

module Search
  DEFAULT_LIMIT = 50
  RANK_ORDER = Arel.sql("bm25(search_corpus, 10.0, 1.0)")

  # Global ranked cross-model search. Returns a flat Array of records ordered
  # by FTS5 rank, already filtered through Pundit policy_scope per registered
  # type.
  def self.call(query, user:, types: Corpus.registry, limit: DEFAULT_LIMIT)
    match = build_match(query)
    return [] if match.blank?

    type_names = types.map { |k| k.base_class.name }
    rows = SearchRow
      .where(searchable_type: type_names)
      .where("search_corpus MATCH ?", match)
      .order(RANK_ORDER)
      .limit(limit)
      .pluck(:searchable_type, :searchable_id)

    hydrate(rows, user)
  end

  # Scoped, composable. Returns Array<Integer> of ids matching `klass` (keyed
  # on its base class in the corpus). Caller applies its own policy_scope and
  # any additional ActiveRecord scopes — used by ContentsController and
  # FeedsController so search composes with the existing `?scope=` toggle.
  def self.matching_ids(query, klass, limit: 200)
    match = build_match(query)
    return [] if match.blank?

    SearchRow
      .where(searchable_type: klass.base_class.name)
      .where("search_corpus MATCH ?", match)
      .order(RANK_ORDER)
      .limit(limit)
      .pluck(:searchable_id)
  end

  # Build a safe FTS5 MATCH expression by allowlist construction. Tokenize on
  # non-word characters, drop empties, wrap each token in double quotes, and
  # append `*` for prefix matching. Keeps FTS5 syntax characters
  # (`"`, `*`, `:`, `^`, `(`, `)`, `NEAR`, `AND`, `OR`, `NOT`, `+`, `-`) out
  # of the parser entirely.
  def self.build_match(query)
    return nil if query.blank?

    tokens = query.to_s.split(/\W+/).reject(&:empty?)
    return nil if tokens.empty?

    tokens.map { |t| %("#{t}"*) }.join(" ")
  end

  def self.hydrate(rows, user)
    grouped = rows.group_by { |r| r[0] }

    by_id = grouped.each_with_object({}) do |(type, type_rows), memo|
      klass = Corpus.resolve(type)
      next unless klass

      ids = type_rows.map { |r| r[1] }
      records = Pundit.policy_scope!(user, klass).where(id: ids).index_by(&:id)
      memo[type] = records
    end

    rows.filter_map { |type, id| by_id.dig(type, id) }
  end
end
