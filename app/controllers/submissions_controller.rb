class SubmissionsController < ApplicationController
  load_and_authorize_resource
  helper :contents

  def index
    @this_feed = Feed.find(params[:feed_id])
    @can_moderate_feed = can?(:update, @this_feed)
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

  # PUT /feeds/1/submissions/1
  def update
    @submission = Submission.find(params[:id])
    @submission.moderator = current_user

    respond_to do |format|
      if @submission.update_attributes(params[:submission])
        format.html { redirect_to(feed_submissions_path, :notice => t(:content_moderated)) }
      else
        format.html { redirect_to(feed_submission_path, :notice => t(:content_failed_moderation)) }
      end
    end
  end

end
