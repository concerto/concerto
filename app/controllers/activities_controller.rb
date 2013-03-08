class ActivitiesController < ApplicationController
  def index
    #Don't even look at this - it makes PHP look clean - and makes you realize why the Rails core team needed a database systems course under its collective belt
    #Only show activities the current user is an owner or a recipient of...easy
    t = PublicActivity::Activity.arel_table
    @activities = PublicActivity::Activity.where((t[:owner_id].eq(current_user.id).and(t[:owner_type].eq('User')).or(t[:recipient_id].eq(current_user.id).and(t[:recipient_type].eq('User')))))
  end
end

