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
    self.config = {} if !self.config
    self.config = default_config().merge(self.config)
  end

  # Specify the default configuration hash.
  # This will be used if a configuration doesn't exist.
  #
  # @return [Hash{String => String, Number}] configution hash.
  def default_config
    {
      'interval' => 300,
    }
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
      if self.config.include? 'last_refresh_attempt'
        return Clock.time.to_i > (self.config['interval'] + self.config['last_refresh_attempt'])
      else
        return true
      end
    else
      return false
    end
  end

  # Actually do the refreshing of content entries.
  # Calls {#build_content} to return an array of new partial content objects,
  # then copies over the defaults if necessary such as `user`, `duration`,
  # `start_time` (now), and `end_time` (now + 1 day).
  #
  # All Submissions that this piece of DynamicContent has are copied to the
  # child content too, including any moderation status.
  #
  # After all the child content are sucessfully saved with submissions we
  # expire the old set of child content with {#expire_children}.
  #
  # @return [Boolean] indicating if the content was sucessfully updated.
  def refresh_content
    # Capture the existing children.
    old_content = self.children.all
    # Build the new ones
    new_content = build_content()
    if !new_content
      return false  # A nil or false build_content result is bad.
    end
    # Copy over base properties to all the new children if needed
    new_content.each do |content|
      content.transaction do
        content.parent = self
        content.user ||= self.user
        content.duration ||= self.duration
        content.start_time ||= Clock.time
        content.end_time ||= Clock.time + 1.day
        if content.save
          self.submissions.each do |model_submission|
            submission = model_submission.dup
            submission.content = content
            submission.save
          end
        else
          raise ActiveRecord::Rollback
          return false
        end
      end
    end

    # Now we'll expire all the old content.
    expire_children(old_content)

    return true
  end

  # Build all the new child content.
  # This is where you usually want to do the heavy thinking.
  #
  # @return [Array, nil, false] array of displayable content items or
  #    nil / false indicating a problem occured.
  def build_content
    []
  end
  
  # Remove stale dynamic content by expiring all child content.
  # Sets the `end_time` of children to the current time.
  def expire_children(opt_children=nil)
    children_to_expire = opt_children || self.children
    children_to_expire.each do |child|
      child.end_time = Clock.time
      child.save
    end
  end

  # Destroy all dynamic content children.
  # You probably never want to do this, but it's useful if things are broken.
  def destroy_children!
    self.children.each do |child|
      child.destroy
    end
  end

  # Update all the DynamicContent.
  # Find all the DynamicContent classes, find all the active content they have,
  # and then #{refresh} them.  Primarily invoked by our rake task.
  def self.refresh
    dynamic_types = Concerto::Application.config.content_types.select do |t|
      t.ancestors.include?(DynamicContent)
    end
    dynamic_types.each do |content_type|
      Rails.logger.info "Updating #{content_type.name}."
      contents = content_type.active.all
      contents.each do |content|
        Rails.logger.info "Thinking about updating #{content.id} - #{content.name}."
        content.refresh
      end
    end
    Rails.logger.info "Dynamic content updates finished."
  end

  # Use a pid to ensure that only one dynamic content refresher is running.
  # If the pid doesn't exist, call #{self.refresh}.
  def self.pid_locked_refresh
    FileUtils.mkdir_p(Rails.root.join('tmp', 'pids'))
    pid_name = Rails.root.join('tmp', 'pids', 'dynamic_content_refresh')
    if File.exists?(pid_name)
      Rails.logger.info "Not updating dynamic content, pid exists"
    end
    
    File.open(pid_name, 'w') {}
    begin
      DynamicContent.refresh
      sleep(60)
    ensure
      File.delete(pid_name)
    end
  end

  # If DynamicContent is updating outside of a cron enviroment, this check
  # should figure out how frequently {self.pid_locked_refresh} should be run.
  #
  # @return [Boolean] indicating if an update should be kicked off
  def self.should_cron_run?
    if ConcertoConfig[:use_frontend_to_trigger_cron] == "false"
      return false
    else
      last_updated = ConcertoConfig[:dynamic_refresh_time].to_i
      return last_updated + 300 < Clock.time.to_i
    end
  end

  # Write back that the cron job has just run.
  def self.cron_ran
    ConcertoConfig.set("dynamic_refresh_time", Clock.time.to_i) 
  end
end
