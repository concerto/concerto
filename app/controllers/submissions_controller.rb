class SubmissionsController < ApplicationController
  load_and_authorize_resource
  helper :contents

  def index
    @this_feed = Feed.find(params[:feed_id])
    @sub_feeds = @this_feed.children
    @submissions = Submission.where(:feed_id => params[:feed_id])

    respond_to do |format|
      format.js { }
      format.html { }
    end
  end

  def show
    @submission = Submission.find(params[:id])

    respond_to do |format|
      format.js { }
      format.html { }
    end
  end

  # PUT /feeds/1/submission/1/approve
  def approve
    submission = Submission.find(params[:id])
    respond_to do |format|
      if submission.approve(current_user, params[:submission][:moderation_reason], params[:submission][:duration])
        format.html { redirect_to(feed_submissions_path, :notice => t(:content_approved)) }
      else
        format.html { redirect_to(feed_submission_path, :notice => t(:content_failed_approve)) }
      end
    end
  end

  # PUT /feeds/1/submission/1/deny
  def deny
    submission = Submission.find(params[:id])
    respond_to do |format|
      if submission.deny(current_user, params[:submission][:moderation_reason])
        format.html { redirect_to(feed_submissions_path, :notice => t(:content_denied)) }
      else
        logger.debug submission.errors
        format.html { redirect_to(feed_submission_path, :notice => t(:content_failed_deny)) }
      end
    end
  end

end
