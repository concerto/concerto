class ActivityMailer < ActionMailer::Base
  def submission_update(activity)
    @activity = activity
    if @activity.trackable.content.user.receive_moderation_notifications?
      mail to: @activity.recipient.email, subject: "Your Concerto Submission: #{@activity.trackable.content.name} has been #{@activity.parameters[:status] ? "approved" : "denied"}", from: @activity.owner.email
    end
  end

  def test_email(to)
    mail to: to, 
      subject: t('.subject'), 
      body: t('.body'),
      from: ConcertoConfig[:mailer_from]
  end
end
