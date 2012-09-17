#Current configuration keys:
  #public_concerto
  #default_upload_type
  #content_default_start_time
  #content_default_end_time
  #setup_complete
  #default_content_run_time
  #start_date_offset

#Adding a new configuration variable:
  #Either in your plugin, or in the seeds file, add a row as such:
  #  ConcertoConfig.find_or_create_by_key(:key => "default_upload_type", :value => "graphic", :value_default => "graphic", :value_type => "string")
  #The value type and default will allow the Dashboard to properly create the form for editing the variable
  #Also ensure to provide a translation in an appropriate YAML file:
  #  default_upload_type: "Default content upload type"
  
  #The variable can then be accessed like this: ConcertoConfig[:public_concerto]
  #and modified by calling ConcertoConfig.set(public_concerto,true)

class ConcertoConfig < ActiveRecord::Base
  
  TRUE  = "t"
  FALSE = "f"

  validates_presence_of   :key
  validates_uniqueness_of :key

  # Enable hash-like access to table for ease of use
  # Shortcut for self.get(key)
  def self.[](key)
    self.get(key.to_s)
  end
  
  #Make setting values from Rails nice and easy
  def self.set(key,value)
    #only set this if the config already exists
    setting = ConcertoConfig.where(:key => key).first # || ConcertoConfig.new(:key => key) 
    setting.update_column(:value, value)
  end  

  # Make getting values from Rails nice and easy
  # Returns false if key isn't found
  def self.get(key)
    setting = ConcertoConfig.where(:key => key).first
    if setting.nil?
      return false
    end
    return setting.value
  end
  
  #Creates a Concerto Config entry by taking the key and value desired
  #Also takes the following options: value_type, value_default, name, group, description, plugin_config, and plugin_id
  #If they're not specified, the type is assumed to be string and the default value the key that is set
  def self.make_concerto_config(config_key,config_value, options={})
    defaults = {
      :value_type => "string",
      :value_default => config_key
    }
    options = defaults.merge(options)
    #first_or_create check whether first returns nil or not; if it does return nil, create is called
    ConcertoConfig.where(:key => config_key).first_or_create(:key => config_key, :value => config_value,
      :value_default => options[:value_default], :value_type => options[:value_type], :name => options[:name], :group => options[:group],
      :description => options[:description], :plugin_config => options[:plugin_config], :plugin_id => options[:plugin_id])
  end  
    
end

