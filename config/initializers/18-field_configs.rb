Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

# A hashes of some of the possible field configs.
# Each hash entry represents a possible field config.
# The entries must contain a Hash with :type set.
# :type must be set to one of :string, :select, or :boolean.
# If :type is set to :select. :values may also be provided.
transitions = ['replace', 'fade-in-animation', 'fade-out-animation',
               'scale-down-animation', 'scale-up-animation',
               'slide-down-animation', 'slide-up-animation',
               'slide-left-animation', 'slide-right-animation',
               'slide-from-left-animation', 'slide-from-right-animation']

Concerto::Application.config.field_configs = {
  entry_transition: {type: :select, values: transitions},
  exit_transition: {type: :select, values: transitions},
  time_format: {type: :string},
  disable_text_autosize: {type: :boolean},
  shuffler: {type: :select, values: ['BaseShuffle', 'WeightedShuffle']},
  repeat_content: {type: :select, values: ['Suppress', 'Reload']}

}

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"
