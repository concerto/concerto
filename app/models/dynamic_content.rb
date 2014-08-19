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
  # Existing child content for this entry are re-purposed if possible to avoid
  # flooding the database with new content / submissions.
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

    new_children = []
    old_reuse_count = [old_content.count, new_content.count].min
    new_count = [0, new_content.count - old_content.count].max
    leftover_count = [0, old_content.count - new_content.count].max

    Rails.logger.debug("Reusing #{old_reuse_count}, Making #{new_count}, Trashing #{leftover_count}.")

    new_children.concat(old_content.slice(0, old_reuse_count))
    # Here we add a bunch of empty new contents.  We can't do the traditional Content.new * N because it will
    # create N copies of the same object, not N new objects.
    (1..new_count).each do |unused_i|
      new_children << Content.new
    end
    old_children = old_content.slice(old_content.count - leftover_count, leftover_count)

    # Copy over base properties to all the new children if needed
    new_content.each_with_index do |content, index|
      content.transaction do
        content.parent = self
        content.user ||= self.user
        content.duration ||= self.duration
        content.start_time ||= Clock.time
        content.end_time ||= Clock.time + 1.day

        new_children[index].becomes(content.class)
        new_attributes = content.attributes
        locked_attributes = ['id', 'created_at', 'updated_at']
        locked_attributes.each do |attr|
          new_attributes.delete(attr)
        end
        new_children[index].assign_attributes(new_attributes, :without_protection => true)

        if new_children[index].save
          # After saving process the submissions.
          self.submissions.each do |model_submission|
            submission = new_children[index].submissions.where(:feed_id => model_submission.feed_id).first
            if submission.nil?
              # The child content doesn't have this submission, create one.
              submission = model_submission.dup
              submission.content = new_children[index]
              submission.save
            else
              # The child content has a similiar submission, update it to match the content.
              submission.moderation_flag = model_submission.moderation_flag
              submission.moderator_id = model_submission.moderator_id
              submission.duration = model_submission.duration
              submission.moderation_reason = model_submission.moderation_reason
              submission.save
            end
          end
        else
          raise ActiveRecord::Rollback
          return false
        end
      end
    end

    # Now we'll expire all the old content.
    expire_children(old_children)

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
  # Sets the `end_time` of children to the current time if it's
  # not already expired.
  def expire_children(opt_children=nil)
    children_to_expire = (opt_children || self.children).to_a
    children_to_expire.reject!{ |child| child.is_expired? }
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

  # Allow dynamic content to be manually refreshed.
  def action_allowed?(action_name, user)
    available = [:manual_refresh, :delete_children]
    return available.include?(action_name)
  end

  # Manually refresh the dynamic content, only if the user
  # has permission to edit the content.
  def manual_refresh(options)
    # Only someoneone who can edit the content can do this.
    owner = Ability.new(options[:current_user])
    if owner.cannot?(:edit, self)
      return I18n.t(:sorry_access)
    end
    if refresh!
      return I18n.t(:content_refreshed)
    else
      return I18n.t(:error_refreshing)
    end
  end

  # Delete all the children of a dynamic content entry.
  # Might be useful if things get broken / out of sync.
  def delete_children(options)
    # Only someoneone who can edit the content can do this.
    owner = Ability.new(options[:current_user])
    if owner.cannot?(:edit, self)
      return I18n.t(:sorry_access)
    end
    self.children.each do |c|
      c.destroy
    end
    return I18n.t(:content_deleted)
  end

  # Manually refresh the dynamic content each time it is
  # added to a submission.  If we were smarter we would
  # wait for all of these to finish but that is left as
  # exercise to the reader.
  def after_add_callback(unused_submission)
    refresh!
  end
end
