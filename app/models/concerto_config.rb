#Current configuration keys:
#:public_concerto
#:default_upload_type
#:content_default_start_time
#:content_default_end_time
#:content_default_duration

class ConcertoConfig < ActiveRecord::Base
  
  TRUE  = "t"
  FALSE = "f"

  validates_presence_of   :key
  validates_uniqueness_of :key

  # Enable hash-like access to table for ease of use
  # Returns false if key isn't found
  # Example: ConcertoConfig[:public_concerto] => "true"
  def self.[](key)
    rec = self.find_by_key(key.to_s)
    if rec.nil?
      return false
    end
    rec.value
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

