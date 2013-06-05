# Adding a new configuration variable:
  # Either in your plugin, or in the seeds file, add a row as such:
  #  ConcertoConfig.find_or_create_by_key(:key => "default_upload_type", :value => "graphic", :value_default => "graphic", :value_type => "string")
  # The value type and default will allow the Dashboard to properly create the form for editing the variable
  # Also ensure to provide a translation in an appropriate YAML file:
  #  default_upload_type: "Default content upload type"
  
  # The variable can then be accessed like this: ConcertoConfig[:public_concerto]
  # and modified by calling ConcertoConfig.set(public_concerto,true)

class ConcertoConfig < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates_presence_of   :key
  validates_uniqueness_of :key

  after_destroy :cache_expire

  # Enable hash-like access to table for ease of use
  # Shortcut for self.get(key)
  def self.[](key)
    self.get(key.to_s)
  end
  
  # Make setting values from Rails nice and easy
  def self.set(key,value)
    setting = ConcertoConfig.where(:key => key).first
    if setting.nil?
      setting = ConcertoConfig.new(:key => key)
      setting.save
    end
    setting.update_column(:value, value)
    ConcertoConfig.cache_expire
  end  

  # Make getting values from Rails nice and easy
  # Returns false if key isn't found or the config is broken.
  def self.get(key, allow_cache=false)
    # First try a cache hit.
    begin
      if allow_cache
        cache_value = ConcertoConfig.cache_get(key)
        return cache_value if !cache_value.nil?
      end
    rescue Exception => e
      Rails.logger.info("Config cache read failed - #{e.message}")
    end

    setting = ConcertoConfig.where(:key => key).first
      if setting.nil?
        raise "Concerto Config key #{key} not found!"
      end    
    if setting.value_type == "boolean"
      setting.value == "true" ? (return true) : (return false)
    end

    # Rebuild the cache if there was a cache miss.
    begin
      ConcertoConfig.cache_rebuild if allow_cache
    rescue Exception => e
      Rails.logger.info("Config cache rebuild failed - #{e.message}")
    end

    return setting.value
  end
  
  # Creates a Concerto Config entry by taking the key and value desired
  # Also takes the following options: value_type, value_default, name, group, description, plugin_config, and plugin_id
  # If they're not specified, the type is assumed to be string and the default value the key that is set
  def self.make_concerto_config(config_key,config_value, options={})
    defaults = {
      :value_type => "string",
      :value_default => config_value
    }
    options = defaults.merge(options)
    # first_or_create: check whether first returns nil or not; if it does return nil, create is called
    ConcertoConfig.where(:key => config_key).first_or_create(:key => config_key, :value => config_value,
      :value_default => options[:value_default], :value_type => options[:value_type], :name => options[:name], :group => options[:group],
      :description => options[:description], :plugin_config => options[:plugin_config], :plugin_id => options[:plugin_id], :hidden => options[:hidden])
  end  

  # Update the config_last_updated entry to indicate the cached data is no longer valid.
  def self.cache_expire
    updated = ConcertoConfig.where(:key => 'config_last_updated').first
    if !updated.nil?
      updated.update_column(:value, Time.now)
    end
  end
  def cache_expire
    ConcertoConfig.cache_expire
  end

  # Attempt to get a key from the cache.
  # Load the cache and return the key if it exists and if the cache's last update
  # is not older than the config's last update.
  def self.cache_get(key)
    last_updated = ConcertoConfig.get('config_last_updated', false)
    return nil if last_updated.nil?  # No validation data for the cache.

    hit = Rails.cache.read('ConcertoConfig')

    if hit.nil? || hit[key].nil? || hit['config_last_updated'].nil? || last_updated != hit['config_last_updated']
      return nil
    else
      return hit[key]
    end
  end

  # Rebuild the entire cache.
  # Dump the whole config and build a hash of the keys and values.
  # We include the last update entry in this hash and use it later for cache validation.
  def self.cache_rebuild()
    data = {}
    ConcertoConfig.all.each do |config|
      data[config.key] = config.value
    end
    Rails.cache.write('ConcertoConfig', data)
  end
end

