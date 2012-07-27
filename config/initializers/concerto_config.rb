#Initialize all core Concerto Config entries
#first_or_create check whether first returns nil or not; if it does return nil, create is called
  
#Creates a Concerto Config entry by taking the key and value desired
#Also takes the following options: value_type, value_default, name, group, description, plugin_config, and plugin_id
#If they're not specified, the type is assumed to be string and the default value the key that is set
def make_concerto_config(config_key,config_value, options={})
  defaults = {
    :value_type => "string",
    :value_default => config_key
  }
  options = defaults.merge(options)
  ConcertoConfig.where(:key => config_key).first_or_create(:key => config_key, :value => config_value, :value_default => options[:value_default], :value_type => options[:value_type], :name => options[:name], :group => options[:group], :description => options[:description], :plugin_config => options[:plugin_config], :plugin_id => options[:plugin_id])
end

if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  make_concerto_config("default_upload_type", "graphic")
  make_concerto_config("public_concerto", "true", :value_type => "boolean")
  make_concerto_config("content_default_start_time", "12:00 am")
  make_concerto_config("content_default_end_time", "11:59 pm")
  make_concerto_config("start_date_offset", "0", :value_type => "integer")
  make_concerto_config("default_content_run_time", "7", :value_type => "integer")
  make_concerto_config("setup_complete", "false", :value_type => "boolean", :value_default => "true")
  make_concerto_config("allow_registration", "true", :value_type => "boolean")
  make_concerto_config("allow_user_screen_creation", "false", :value_type => "boolean")
  make_concerto_config("rubygem_executable", "gem")
end











