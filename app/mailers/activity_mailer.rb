class ActivityMailer < ActionMailer::Base
  def content_moderated(activity)
    @activity = activity
    mail :to => @activity.recipient.email, :subject => "Your Concerto Submission: #{@activity.trackable.content.name} has been #{@activity.parameters[:status] ? "approved" : "denied"}", :from => @activity.owner.email 
  end
end
