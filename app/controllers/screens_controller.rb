class ScreensController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_screen, only: %i[ show edit update destroy ]
  before_action :set_form_options, only: %i[ new edit create update ]


  # Ensure that Pundit authorization has been performed for every action.
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /screens or /screens.json
  def index
    @screens = policy_scope(Screen)
  end

  # GET /screens/1 or /screens/1.json
  def show
    authorize @screen
    @subscriptions_by_field = @screen.subscriptions.includes(:feed).group_by(&:field_id)
    @field_configs_by_field = @screen.field_configs.includes(:pinned_content).where.not(pinned_content_id: nil).index_by(&:field_id)
  end

  # GET /screens/new
  def new
    @screen = Screen.new
    authorize @screen
  end

  # GET /screens/1/edit
  def edit
    authorize @screen
    # Pre-load field configs to avoid N+1 queries in the form
    @field_configs_by_field = @screen.field_configs.index_by(&:field_id) if @screen.persisted?
  end

  # POST /screens or /screens.json
  def create
    @screen = Screen.new(screen_params)

    authorize @screen

    respond_to do |format|
      if @screen.save
        format.html { redirect_to screen_url(@screen), notice: "Screen was successfully created." }
        format.json { render :show, status: :created, location: @screen }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @screen.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /screens/1 or /screens/1.json
  def update
    @screen.assign_attributes(screen_params)

    authorize @screen

    respond_to do |format|
      if @screen.save
        format.html { redirect_to screen_url(@screen), notice: "Screen was successfully updated." }
        format.json { render :show, status: :ok, location: @screen }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @screen.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /screens/1 or /screens/1.json
  def destroy
    authorize @screen

    @screen.destroy!

    respond_to do |format|
      format.html { redirect_to screens_url, notice: "Screen was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_screen
      @screen = Screen.find(params[:id])
    end

    # Sets options for form selects.
    #
    # NOTE: This method's group logic is duplicated in FeedsController#set_form_options.
    # If you modify the group selection logic here, update FeedsController to match.
    # (Not extracted to a concern to keep controller logic simple and conventional.)
    def set_form_options
      @templates = Template.all.with_attached_image
      @active_content = Content.active.order(:name)
      if current_user.system_admin?
        @groups = Group.all
      else
        # In an edit context, ensure the screen's current group is in the list for display,
        # even if the user is not an admin of it. They won't be able to *switch* to it,
        # but they should be able to see it.
        @groups = if @screen&.persisted?
          (current_user.admin_groups + [ @screen.group ]).compact.uniq
        else
          current_user.admin_groups
        end
      end
    end

    # Only allow a list of trusted parameters through.
    def screen_params
      params.require(:screen).permit(policy(@screen || Screen.new()).permitted_attributes)
    end
end
