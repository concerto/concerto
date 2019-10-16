class SubmissionsController < ApplicationController
  before_filter :get_feed
  helper :contents

  def get_feed
    @feed = Feed.find(params[:feed_id])
    auth!(action: :show, object: @feed)
  end

  # GET /feeds/:feed_id/submissions
  # GET /feeds/:feed_id/submissions.js
  def index
    @can_moderate_feed = can?(:moderate, @feed)

    state = params[:state] || 'active'

    @submissions = []
    case state
    when 'expired'
      @submissions = @feed.submissions.approved.expired.reorder('contents.end_time desc')
    when 'future'
      @submissions = @feed.submissions.approved.future.reorder('contents.start_time')
    when 'pending'
      @submissions = @feed.submissions.pending.reorder('contents.start_time')
    when 'denied'
      @submissions = @feed.submissions.denied.reorder('submissions.updated_at desc')
    else
      @submissions = @feed.submissions.approved.active.reorder('submissions.seq_no, submissions.id')
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

  # GET /feeds/:feed_id/submissions/1/reorder?before=
  # GET /feeds/:feed_id/submissions/1/reorder?before=.js
  def reorder
    @submission = Submission.find(params[:id])
    if cannot?(:moderate, @feed)
      head :forbidden
    else
      @before = Submission.find(params[:before])
      if @submission.blank? || @before.blank?
        head :not_found
      else
        @submissions = @feed.submissions.approved.active.reorder('submissions.seq_no, contents.start_time')
        seq_no = 0
        reserved_slot = 0
        parent_seq_nos = {}
        @submissions.each do |s|
          # child content also has a submission record, and its seq_no should match it's parent, so skip the children here
          next if s.content.parent.present?

          seq_no = seq_no + 1
          if s.id == @before.id
            reserved_slot = seq_no
            seq_no = seq_no + 1
            s.seq_no = seq_no
          elsif s.id == @submission.id
            s.seq_no = reserved_slot
          else
            s.seq_no = seq_no
          end
          s.save

          # keep track of each parent's seq_no so we can set their children
          if s.content.children_count > 0
            parent_seq_nos[s.content.id] = s.seq_no
          end
        end
        @submissions.each do |s|
          next if s.content.parent.blank?
          s.seq_no = parent_seq_nos[s.content.parent.id]
          s.save
        end

        head :ok
      end
    end
  end

  # GET /feeds/:feed_id/submissions/1
  # GET /feeds/:feed_id/submissions/1.js
  def show
    @submission = Submission.find(params[:id])
    auth!
    
    # IMPORTANT: .load must be at the end of the collection to eager load and prevent the actual object from being deleted!
    @other_submissions = @submission.content.submissions.to_a
    
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
          params: {
            status: @submission.moderation_flag,
            content_name: @submission.content.name,
            feed_name: @submission.feed.name
            }, 
          recipient: @submission.content.user}))
        format.html { redirect_to(feed_submissions_path, notice: t(:content_moderated)) }
        format.js
      else
        format.html { redirect_to(feed_submission_path, notice: t(:content_failed_moderation)) }
        format.js
      end
    end
  end

private

  def submission_params
    params.require(:submission).permit(:moderation_reason, :moderation_flag, :duration)
  end

end
