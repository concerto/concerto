# Be sure to restart your server when you modify this file.

Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

# This file contains settings for ActionController::ParamsWrapper which
# is enabled by default.

# Enable parameter wrapping for JSON. You can disable this by setting :format to an empty array.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json]
end

# To enable root element in JSON for ActiveRecord objects.
# ActiveSupport.on_load(:active_record) do
#  self.include_root_in_json = true
# end

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"
