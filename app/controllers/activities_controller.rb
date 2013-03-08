class ActivitiesController < ApplicationController
  def index
    if current_user
      #Don't even look at this - it makes PHP look clean - and makes you realize why the Rails core team needed a database systems course under its collective belt
      #Only show activities the current user is an owner or a recipient of...easy
      t = PublicActivity::Activity.arel_table
      @activities = PublicActivity::Activity.where(
        (t[:owner_id].eq(current_user.id).and(t[:owner_type].eq('User'))
        .or(t[:recipient_id].eq(current_user.id).and(t[:recipient_type].eq('User')))))
        .limit(50)
        
      @public_activities = PublicActivity::Activity.where(:owner_id => nil, :recipient_id => nil).limit(25)
      
      @activities += @public_activities
    end
  end
end

