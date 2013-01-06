# DynamicContent serves as the base class for all Dynamic Content and is
# responsible for saving the final content entries generated.  Also provided
# are a handful of default behaviors for refreshing content and managing a
# configuration datastore (JSON encoded).
class DynamicContent < Content
  after_initialize :set_kind, :create_config

  after_find :load_config
  before_validation :save_config

  attr_accessor :config

  # Automatically set the kind for the content
  # if it is new.  We use this hidden type that no fields
  # render so Dynamic Content meta content never gets displayed.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(:name => 'Dynamic').first
  end

  # Create a new configuration hash if one does not already exist.
  # Called during `after_initialize`, where a config may or may not exist.
  def create_config
    self.config = self.config || {}
  end

  # Load a configuration hash.
  # Converts the JSON data stored for the content into the configuration.
  # Called during `after_find`.
  def load_config
    self.config = JSON.load(self.data)
  end

  # Prepare the configuration to be saved.
  # Compress the config hash back into JSON to be stored in the database.
  # Called during `before_valication`.
  def save_config
    self.data = JSON.dump(self.config)
  end

  # Refresh this dynamic content if necessary, as determined by
  # {#refresh_needed?}.
  def refresh
    refresh! if refresh_needed?
  end

  # Refresh this dynamic content.
  # Update the timing information based on how well the refresh goes.
  # If a refresh succeeds, `last_ok_refresh` will have the time the refresh
  # finished.  If it fails, `last_bad_refresh` will store the time.
  def refresh!
    self.config['last_refresh_attempt'] = Clock.time.to_i
    refresh_status = refresh_content()
    if refresh_status
      self.config['last_ok_refresh'] = Clock.time.to_i
    else
      self.config['last_bad_refresh'] = Clock.time.to_i
      Rails.logger.error("Trouble refreshing dynamic content")
    end
    self.save
  end

  # Should we refresh?
  # If an `interval` config option is set, see if that many seconds have passed
  # since the last refresh attempt. If an `interval` config option is not set,
  # assume a refresh is not needed.
  def refresh_needed?
    if self.config.include? 'interval'
      return Clock.time.to_i > (self.config['interval'] + self.config['last_refresh_attempt'])
    else
      return false
    end
  end

  # Actually do the refreshing of content entries.
  #
  # @return [Boolean] indicating if the content was sucessfully updated.
  def refresh_content
    true
  end
  
  # Remove stale dynamic content by expiring all child content.
  # Sets the `end_time` of children to the current time.
  def expire_children
    self.children.each do |child|
      child.end_time = Clock.time
      child.save
    end
  end

end
