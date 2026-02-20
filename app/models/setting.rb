class Setting < ApplicationRecord
  encrypts :encrypted_value

  validates :key, presence: true, uniqueness: true

  # Getter for type casting
  def typed_value
    case value_type
    when "integer" then value.to_i
    when "boolean" then value == "true"
    when "array", "hash" then JSON.parse(value)
    when "secret" then encrypted_value
    when "string" then value # Default for string
    else value # Fallback if value_type is nil or unknown
    end
  rescue JSON::ParserError
    value_type == "array" ? [] : {}
  end

  # Setter for type casting and setting the string value_type
  def typed_value=(val)
    if value_type == "secret"
      self.encrypted_value = val.to_s
      return
    end

    self.value_type = case val
    when Integer then "integer"
    when TrueClass, FalseClass then "boolean"
    when Array then "array"
    when Hash then "hash"
    else "string" # Default for unknown types
    end
    self.value = val.is_a?(Array) || val.is_a?(Hash) ? val.to_json : val.to_s
  end

  # Helper methods for easy access (remain unchanged)
  def self.[](key)
    Rails.cache.fetch("settings/#{key}") do
      find_by(key: key)&.typed_value
    end
  end

  def self.[]=(key, val)
    setting = find_or_initialize_by(key: key)
    # If we already have a value_type, try to convert the incoming value accordingly
    if setting.persisted? && setting.value_type
      val = case setting.value_type
      when "integer" then val.to_i
      when "boolean" then val.to_s == "true"
      when "secret" then val.to_s
      when "array" then
        begin
          JSON.parse(val.is_a?(String) ? val : val.to_json)
        rescue JSON::ParserError
          []
        end
      when "hash" then
        begin
          JSON.parse(val.is_a?(String) ? val : val.to_json)
        rescue JSON::ParserError
          {}
        end
      else val
      end
    end
    setting.typed_value = val
    setting.save
  end

  # Cache invalidation
  after_commit :clear_cache

  private

  def clear_cache
    Rails.cache.delete("settings/#{key}")
  end
end
