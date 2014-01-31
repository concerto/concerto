module DashboardHelper  
  # Check if the background processor is running or not
  # by looking at it's heartbeat and comparing it to a threshold.
  def background_processor_running?
    last_update = ConcertoConfig[:worker_heartbeat]
    threshold = Delayed::Worker.sleep_delay * 4
    return (Clock.time.to_i - last_update.to_i) < threshold
  end

  # Get the owner of the activity, linkable if possible.
  #
  # @param [PublicActivity::Activity] activity Activity instance from which to obtain the owner.
  #   If the owner no longer exists, owner_name from the parameters will be used, if it exists.
  # @return [String] The possibly linkable owner of the activity.
  def get_activity_owner(activity)
    if activity.owner.nil?
      activity.parameters.include?(:owner_name) ? activity.parameters[:owner_name] : 'An unknown user'
    else
      if can? :read, activity.owner
        link_to(activity.owner.name, activity.owner)
      else
        activity.owner.name
      end
    end
  end

  # Get the trackable item of the activity, linkable if possible.
  #
  # @param [PublicActivity::Activity] activity Activity instance from which to obtain the item.
  #   If the item no longer exists, the item_name from the parameters will be used, if it exists.
  #   For example, if the trackable activity is a screen then the item_name would be :screen_name.
  # @param [String] attr_name The attribute that represents the name of the instance of the item.
  # @return [String] The possibly linkable trackable item of the activity.
  def get_activity_item(activity, attr_name = 'name')
    if activity.trackable
      if can? :read, activity.trackable
        link_to(activity.trackable.send(attr_name), activity.trackable)
      else
        activity.trackable.send(attr_name)
      end
    else
      trackable_name_sym = (activity.trackable_type.underscore.downcase + '_' + attr_name).to_sym
      if activity.parameters.include?(trackable_name_sym)
        activity.parameters[trackable_name_sym]
      else
        t('public_activity.which_has_since_been_removed')
      end
    end
  end

  # Generates the entire view for an activity.
  #
  # @param [PublicActivity::Activity] activity Activity instance.
  #   This requires a translation key of "#{action}_the_model" and uses the trackable type's model's human name.
  # @param [String] attr_name The attribute that represents the name of the instance of the item.
  # @return [String] The view contents.
  def generate_activity_view(activity, attr_name = 'name')
    action = activity.key.split(".").last
    results = get_activity_owner(activity) + 
      " " + t((action + "_the_model").to_sym, :model => activity.trackable_type.classify.safe_constantize.model_name.human.downcase) +
      " " + get_activity_item(activity, attr_name)
    results.html_safe
  end
end
