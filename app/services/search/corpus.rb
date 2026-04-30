# frozen_string_literal: true

module Search
  module Corpus
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
        SearchRow.transaction do
          SearchRow.where(searchable_type: type, searchable_id: record.id).delete_all
          SearchRow.insert_all!([ {
            searchable_type: type,
            searchable_id: record.id,
            name: data[:name].to_s,
            body: data[:body].to_s
          } ])
        end
      end

      def delete(record)
        SearchRow.where(
          searchable_type: record.class.base_class.name,
          searchable_id: record.id
        ).delete_all
      end

      def rebuild!
        SearchRow.transaction do
          SearchRow.delete_all
          @registry.each do |klass|
            klass.find_each do |record|
              upsert(record, record.searchable_data) if record.searchable?
            end
          end
        end
      end

      def count
        SearchRow.count
      end

      def count_for(klass)
        SearchRow.where(searchable_type: klass.base_class.name).count
      end
    end
  end
end
