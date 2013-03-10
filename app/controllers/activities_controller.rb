class ActivitiesController < ApplicationController
  def index
    if current_user
      #Retrieve the activities for which the current user is an owner or recipient (making sure the STI field specifies user as the Type)       
      @owner = PublicActivity::Activity.where(:owner_id => current_user.id, :owner_type => 'User').limit(25)  
      @recipient = PublicActivity::Activity.where(:recipient_id => current_user.id, :recipient_type => 'User').limit(25)
      
      #Select the activities that involve a group as the recipient for which the user is a member
      @group_member = PublicActivity::Activity.where("recipient_id IN (#{current_user.group_ids.join(", ")}) AND recipient_type = 'Group'").limit(10)
        
      #Select activities with neither an owner nor a recipient (public activities) - the actual owner is set in the parameters hash for these
      @public_activities = PublicActivity::Activity.where(:owner_id => nil, :recipient_id => nil).limit(10)
      
      @activities = @owner + @recipient + @group_member + @public_activities
      @activities.sort! { |a,b| b.created_at <=> a.created_at }
    end
  end
end

