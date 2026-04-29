# frozen_string_literal: true

module Search
  module Corpus
    TABLE = "search_corpus"

    @registry = []

    class << self
      def registry
        @registry
      end

      def register(klass)
        @registry << klass unless @registry.include?(klass)
      end

      def resolve(type)
        @registry.detect { |k| k.name == type }
      end

      def upsert(record, data)
        type = record.class.base_class.name
        id = record.id
        connection.execute(
          ActiveRecord::Base.sanitize_sql_array([
            "DELETE FROM #{TABLE} WHERE searchable_type = ? AND searchable_id = ?",
            type, id
          ])
        )
        connection.execute(
          ActiveRecord::Base.sanitize_sql_array([
            "INSERT INTO #{TABLE} (searchable_type, searchable_id, name, body) VALUES (?, ?, ?, ?)",
            type, id, data[:name].to_s, data[:body].to_s
          ])
        )
      end

      def delete(record)
        connection.execute(
          ActiveRecord::Base.sanitize_sql_array([
            "DELETE FROM #{TABLE} WHERE searchable_type = ? AND searchable_id = ?",
            record.class.base_class.name, record.id
          ])
        )
      end

      def rebuild!
        ActiveRecord::Base.transaction do
          connection.execute("DELETE FROM #{TABLE}")
          @registry.each do |klass|
            klass.find_each do |record|
              upsert(record, record.searchable_data) if record.searchable?
            end
          end
        end
      end

      def count
        connection.select_value("SELECT COUNT(*) FROM #{TABLE}").to_i
      end

      def count_for(klass)
        connection.select_value(
          ActiveRecord::Base.sanitize_sql_array([
            "SELECT COUNT(*) FROM #{TABLE} WHERE searchable_type = ?",
            klass.base_class.name
          ])
        ).to_i
      end

      private

      def connection
        ActiveRecord::Base.connection
      end
    end
  end
end
