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

  # Create a new configuration hash if necessary.
  def create_config
    self.config = self.config || {}
  end

  # Load a configuration hash back from the database to attribute.
  def load_config
    self.config = JSON.load(self.data)
  end

  # Prepare the configuration to be saved.
  def save_config
    self.data = JSON.dump(self.config)
  end

  # Refresh this dynamic content if necessary.
  def refresh
    refresh! if refresh_needed?
  end

  # Refresh this dynamic content regardless of if we should or not.
  # Update the timing information based on how well the refresh goes.
  def refresh!
    self.config['last_refresh_attempt'] = Time.now.to_i
    refresh_status = refresh_content()
    if refresh_status
      self.config['last_ok_refresh'] = Time.now.to_i
    else
      self.config['last_bad_refresh'] = Time.now.to_i
      Rails.logger.error("Trouble refreshing dynamic content")
    end
    self.save
  end

  # Should we refresh?
  # If an 'interval' config option is set, see if that many seconds have
  # passed since the last refresh attempt.
  # If an 'interval' config option is not set, assume a refresh is not needed.
  def refresh_needed?
    if self.config.include? 'interval'
      return Time.now.to_i > (self.config['interval'] + self.config['last_refresh_attempt'])
    else
      return false
    end
  end

  # Actually do the thinking here.
  # Return a boolean indicating if things worked or not.
  def refresh_content
    true
  end

end
