class DashboardController < ApplicationController

  # GET /dashboard
  # GET /dashboard.xml
  # GET /dashboard.js
  def show
    if current_user
      # Browse + Vitals share feeds.
      @feeds = Feed.roots
      auth!(!:object => @feeds)

      # Latest Activities
      @activities = get_activities()

      # Vitals
      @screens = Screen.all
      auth!(:object => @screens)
      @active_content = Content.active.joins(:submissions).merge(Submission.approved).count
      @templates = Template.where(:is_hidden => false)
      can?(:read, ConcertoPlugin) ? @concerto_plugins = ConcertoPlugin : @concerto_plugins = nil

      respond_to do |format|
        format.html { } # index.html.erb
        format.xml  { render :xml => @feeds }
        format.js { render :layout => false }
      end
    else
      redirect_to feeds_path
    end
  end

private

  def get_activities
    activities = []
    if current_user && defined? PublicActivity::Activity
      #Retrieve the activities for which the current user is an owner or recipient (making sure the STI field specifies user as the Type)
      owner = PublicActivity::Activity.where(:owner_id => current_user.id, :owner_type => 'User').limit(25)
      recipient = PublicActivity::Activity.where(:recipient_id => current_user.id, :recipient_type => 'User').limit(25)

      #Select the activities that involve a group as the recipient for which the user is a member
      group_member = PublicActivity::Activity.where(:recipient_id => current_user.group_ids, :recipient_type => "Group").limit(10)

      #Select activities with neither an owner nor a recipient (public activities) - the actual owner is set in the parameters hash for these...let's ditch this arel hack in Rails 4 please
      public_activities = PublicActivity::Activity.where(:owner_id => nil, :recipient_id => nil).where(PublicActivity::Activity.arel_table[:trackable_type].not_eq("ConcertoConfig")).limit(10)
      if current_user.is_admin?
        system_notifications = PublicActivity::Activity.where(:trackable_type => "ConcertoConfig").limit(10)
        activities = owner + recipient + group_member + public_activities + system_notifications
      else
        activities = owner + recipient + group_member + public_activities
      end
      activities.sort! { |a,b| b.created_at <=> a.created_at }
    end
    return activities
  end

end
