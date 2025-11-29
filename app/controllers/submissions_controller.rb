class SubmissionsController < ApplicationController
  before_action :set_submission, only: %i[ show edit update destroy ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /submissions or /submissions.json
  def index
    @submissions = policy_scope(Submission)
  end

  # GET /submissions/1 or /submissions/1.json
  def show
    authorize @submission
  end

  # GET /submissions/new
  def new
    @submission = Submission.new
    authorize @submission
  end

  # GET /submissions/1/edit
  def edit
    authorize @submission
  end

  # POST /submissions or /submissions.json
  def create
    @submission = Submission.new(submission_params)

    authorize @submission

    respond_to do |format|
      if @submission.save
        format.html { redirect_to submission_url(@submission), notice: "Submission was successfully created." }
        format.json { render :show, status: :created, location: @submission }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /submissions/1 or /submissions/1.json
  def update
    authorize @submission

    respond_to do |format|
      if @submission.update(submission_params)
        format.html { redirect_to submission_url(@submission), notice: "Submission was successfully updated." }
        format.json { render :show, status: :ok, location: @submission }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /submissions/1 or /submissions/1.json
  def destroy
    authorize @submission

    @submission.destroy!

    respond_to do |format|
      format.html { redirect_to submissions_url, notice: "Submission was successfully removed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_submission
      @submission = Submission.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def submission_params
      params.require(:submission).permit(:content_id, :feed_id)
    end
end
