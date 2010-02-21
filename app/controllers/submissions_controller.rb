class SubmissionsController < ApplicationController

  def index
    @submissions = Submission.where(:feed_id => params[:feed_id]).pending
  end

  def show
    @submission = Submission.find(params[:id])
  end

  # PUT /feeds/1/submissions/1
  # PUT /feeds/1/submissions/1.xml
  def update
    @submission = Submission.find(params[:id])

    respond_to do |format|
      if @submission.update_attributes(params[:submission])
        format.html { redirect_to(:back, :notice => 'Content was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { redirect_to :back }
        format.xml  { render :xml => @feed.errors, :status => :unprocessable_entity }
      end
    end
  end


end
