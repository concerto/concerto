class DashboardController < ApplicationController

  def list_activities
    @activities = get_activities(100)
  end

  # GET /dashboard
  # GET /dashboard.xml
  # GET /dashboard.js
  def show
    if current_user
      @motd = ConcertoConfig.get(:motd_html)

      # Browse + Vitals share feeds.
      @feeds = Feed.accessible_by(current_ability).roots

      # Latest Activities
      @activities = get_activities(10)

      # Vitals
      @screens = Screen.accessible_by(current_ability)

      if ConcertoConfig[:public_concerto]
        # In public concerto case there are some block based rules that do not work with accessible_by
        # se we need to do the hard work ourselves

        @groups = Group.all
        auth!(action: :index, object: @groups)

        @users = User.all
        auth!(action: :index, object: @users)

      else
        @groups = Group.accessible_by(current_ability)
        @users = User.accessible_by(current_ability)
      end

      @active_content = Content.active.joins(:submissions).merge(Submission.approved).count
      @templates = Template.where(is_hidden: false)
      can?(:read, ConcertoPlugin) ? @concerto_plugins = ConcertoPlugin : @concerto_plugins = nil

      # Admin Stats
      @latest_version = VersionCheck.latest_version

      respond_to do |format|
        format.html { } # show.html.erb
      end
    else
      redirect_to feeds_path
    end
  end

private

  def get_activities(activity_limit)
    activities = []
    if current_user && defined?(PublicActivity::Activity)
      if current_user.is_admin?
        activities = PublicActivity::Activity.order('updated_at desc').limit(activity_limit)
      else
        #Retrieve the activities for which the current user is an owner or recipient (making sure the STI field specifies user as the Type)
        owner = PublicActivity::Activity.where(owner_id: current_user.id, owner_type: 'User').order('updated_at desc').limit(activity_limit)
        recipient = PublicActivity::Activity.where(recipient_id: current_user.id, recipient_type: 'User').order('updated_at desc').limit(activity_limit)

        #Select the activities that involve a group as the recipient for which the user is a member
        group_member = PublicActivity::Activity.where(recipient_id: current_user.group_ids, recipient_type: "Group").order('updated_at desc').limit(activity_limit)

        #Select activities with neither an owner nor a recipient (public activities) - the actual owner is set in the parameters hash for these...let's ditch this arel hack in Rails 4 please
        public_activities = PublicActivity::Activity.where(owner_id: nil, recipient_id: nil).where(PublicActivity::Activity.arel_table[:trackable_type].not_eq("ConcertoConfig")).order('updated_at desc').limit(activity_limit)

        if current_user.is_admin?
          system_notifications = PublicActivity::Activity.where(trackable_type: "ConcertoConfig").order('updated_at desc').limit(activity_limit)
          activities = owner + recipient + group_member + public_activities + system_notifications
        else
          activities = owner + recipient + group_member + public_activities
        end
        activities.sort! { |a,b| b.created_at <=> a.created_at }
        activities.slice!(activity_limit..-1)
      end
    end
    return activities
  end

end
