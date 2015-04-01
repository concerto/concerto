Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

# A hashes of some of the possible field configs.
# Each hash entry represents a possible field config.
# The entries must contain a Hash with :type set.
# :type must be set to one of :string, :select, or :boolean.
# If :type is set to :select. :values may also be provided.

Concerto::Application.config.field_configs = {
  transition: {type: :select, values: ['fade','slide','replace']},
  time_format: {type: :string},
  disable_text_autosize: {type: :boolean},
  marquee: {type: :boolean},
  shuffler: {type: :select, values: ['BaseShuffle', 'WeightedShuffle']}
}

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"
