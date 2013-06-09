#Key-value store for field-specific configurations
class FieldConfig < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates_presence_of :key
  validates_presence_of :field_id
  validates_uniqueness_of :key

  # Enable hash-like access to table for ease of use
  # Shortcut for self.get(key)
  def self.[](key)
    self.get(key.to_s)
  end
  
  # Make setting values from Rails nice and easy
  def self.set(key,value)
    #only set this if the config already exists
    setting = FieldConfig.where(:key => key).first
    setting.update_column(:value, value)
  end  

  # Make getting values from Rails nice and easy
  # Returns false if key isn't found or the config is broken.
  def self.get(key)
    setting = FieldConfig.where(:key => key).first
      if setting.nil?
        raise "Field config key #{key} not found!"
      end    
    if setting.value_type == "boolean"
      setting.value == "true" ? (return true) : (return false)
    end
    return setting.value
  end
  
  # Creates a Field Config entry by taking the key and value desired
  # Also takes the options value_type and value_default
  # If they're not specified, the type is assumed to be string and the default value the key that is set
  def self.make_field_config(field_id, config_key,config_value, options={})
    defaults = {
      :value_type => "string",
      :value_default => config_value
    }
    options = defaults.merge(options)
    # first_or_create: check whether first returns nil or not; if it does return nil, create is called
    FieldConfig.where(:key => config_key).first_or_create(:field_id => field_id, :key => config_key, :value => config_value,
      :value_default => options[:value_default], :value_type => options[:value_type])
  end  
    
end

