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
  # Returns false if key isn't found
  def self.[](key)
    rec = self.find_by_key(key.to_s)
    if rec.nil?
      return false
    end
    rec.value
  end
  
  #Make setting values from Rails nice and easy
  def self.set(key,value)
    setting = ConcertoConfig.where(:key => key).first || ConcertoConfig.new(:key => key)
    setting.update_attribute(:value, value)
  end  

  # Override self.method_missing to allow
  # instance attribute type access to Configuration
  # table. This helps with forms.
  def self.method_missing(method, *args)
    unless method.to_s.include?('find') # skip AR find methods
      value = self[method]
      return value unless value.nil?
    end
    super
  end
end

