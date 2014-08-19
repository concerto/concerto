class SubmissionsController < ApplicationController
  before_filter :get_feed
  helper :contents

  def get_feed
    @feed = Feed.find(params[:feed_id])
    auth!(:action => :show, :object => @feed)
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
    @submissions = @submissions.includes(:content)

    # We only paginate based on the parent content during the active page.
    # Other pages may show submissions without a parent to collect them under,
    # so we paginate directly on them there.  This will probably need cleanup at some point.
    if state == 'active'
      @paginated_submissions = @submissions.select {|s| s.content.parent_id.nil? }
      @paginated_submissions = Kaminari.paginate_array(@paginated_submissions)
    else
      @paginated_submissions = @submissions
    end
    @paginated_submissions = @paginated_submissions.page(params[:page])

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
    auth!
    
    # IMPORTANT: .load must be at the end of the collection to eager load and prevent the actual object from being deleted!
    @other_submissions = @submission.content.submissions.load
    
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
      if @submission.update_attributes(submission_params)
        process_notification(@submission, {}, process_notification_options({
          :params => {
            :status => @submission.moderation_flag,
            :content_name => @submission.content.name,
            :feed_name => @submission.feed.name
            }, 
          :recipient => @submission.content.user}))
        format.html { redirect_to(feed_submissions_path, :notice => t(:content_moderated)) }
        format.js
      else
        format.html { redirect_to(feed_submission_path, :notice => t(:content_failed_moderation)) }
        format.js
      end
    end
  end

private

  def submission_params
    params.require(:submission).permit(:moderation_reason, :moderation_flag, :duration)
  end

end
