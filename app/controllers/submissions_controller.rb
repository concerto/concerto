class SubmissionsController < ApplicationController
  before_filter :get_feed
  helper :contents

  def get_feed
    @feed = Feed.find(params[:feed_id])
  end

  # GET /feeds/:feed_id/submissions
  # GET /feeds/:feed_id/submissions.js
  def index
    @can_moderate_feed = can?(:update, @feed)

    state = params[:state] || 'active'

    @submissions = []
    case state
    when 'expired'
      @submissions = @feed.submissions.approved.expired
    when 'future'
      @submissions = @feed.submissions.approved.future
    when 'pending'
      @submissions = @feed.submissions.pending
    when 'denied'
      @submissions = @feed.submissions.denied
    else
      @submissions = @feed.submissions.approved.active
      state = 'active'
    end
    @paginated_submissions = @submissions
    @paginated_submissions = @submissions.page(params[:page]).per(100) unless @paginated_submissions.kind_of?(Array)
    @state = state

    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  # GET /feeds/:feed_id/submissions/1
  # GET /feeds/:feed_id/submissions/1.js
  def show
    @submission = Submission.find(params[:id])
    
    # IMPORTANT: .all must be at the end of the collection to eager load and prevent the actual object from being deleted!
    @other_submissions = @submission.content.submissions.all
    
    # remove the current submission from the collection of its content's related submissions
    @other_submissions.delete(@submission)

    # Enforce the correct feed ID in the URL
    if @submission.feed != @feed
      redirect_to feed_submissions_path(params[:feed_id])
    end
    auth!

    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  # PUT /feeds/1/submissions/1
  def update
    @submission = Submission.find(params[:id])
    @submission.moderator = current_user
    auth!

    respond_to do |format|
      if @submission.update_attributes(params[:submission])
        @activity = @submission.create_activity :update, :owner => current_user, :recipient => @submission.content.user, :params => {:status => @submission.moderation_flag}
        ActivityMailer.content_moderated(@activity).deliver
        format.html { redirect_to(feed_submissions_path, :notice => t(:content_moderated)) }
      else
        format.html { redirect_to(feed_submission_path, :notice => t(:content_failed_moderation)) }
      end
    end
  end

end
