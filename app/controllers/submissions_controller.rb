class SubmissionsController < ApplicationController
  before_filter :get_feed
  helper :contents

  def get_feed
    @feed = Feed.find(params[:feed_id])
  end

  def index
    @can_moderate_feed = can?(:update, @feed)
    
    # active submissions are defined as submissions that are approved AND either active (i.e. date window has not passed to make them expired) OR future (i.e. date window has not even been met yet):
    @active_submissions = @feed.submissions.approved.active + @feed.submissions.approved.future

    if @can_moderate_feed
      
      # pending submissions are defined as submissions that are active (i.e. date window has not passed to make them expired) and flagged as pending via scope:
      @pending_submissions = @feed.submissions.pending.active
      
      # denied submissions are defined as all submissions that are marked with moderation false (regardless of expired or active status):
      @denied_submissions = @feed.submissions.denied
      
      # expired submissions include any pending or active submissions that have passed their date windows, but denied submissions are not included (i.e. they're ALWAYS in the "denied" list):
      @expired_submissions = @feed.submissions.pending.expired + @feed.submissions.approved.expired
    
    end
    #brzNote: did appears to result in a redirect when it is uncommented:
    #auth!

    respond_to do |format|
      format.js { }
      format.html { }
    end
  end

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
      format.js { }
      format.html { }
    end
  end

  # PUT /feeds/1/submissions/1
  def update
    @submission = Submission.find(params[:id])
    @submission.moderator = current_user
    auth!

    respond_to do |format|
      if @submission.update_attributes(params[:submission])
        format.html { redirect_to(feed_submissions_path, :notice => t(:content_moderated)) }
      else
        format.html { redirect_to(feed_submission_path, :notice => t(:content_failed_moderation)) }
      end
    end
  end

end
