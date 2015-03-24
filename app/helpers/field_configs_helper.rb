module FieldConfigsHelper
  # All the FieldConfig keys from the global config which have not already
  # been used on a Field for a Screen.
  #
  # @param [Screen] screen The current screen.
  # @param [Field] field The current field.
  # @returns [Array<Symbol>] An array of unused keys.
  def get_available_keys(screen, field)
    available_keys = Concerto::Application.config.field_configs.keys
    used_keys = FieldConfig.where(field_id: field.id, screen_id: screen.id).select('field_configs.key').collect{ |field_config| field_config.key.to_sym }
    return available_keys - used_keys
  end
end
