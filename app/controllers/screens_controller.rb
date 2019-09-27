class ScreensController < ApplicationController
  # Define integration hooks for Concerto Plugins
  define_callbacks :destroy # controller callback for 'show' action
  define_callbacks :show # controller callback for 'show' action
  define_callbacks :change # controller callback after 'create' or 'update'
  ConcertoPlugin.install_callbacks(self) # Get the callbacks from plugins
  respond_to :html, :json, :xml
  responders :flash

  # GET /screens
  # GET /screens.xml
  def index
    @screens = Screen.order_by_name.accessible_by(current_ability)
    @my_screens = current_user.nil? ? [] : @screens.select{|s| s.owner == current_user || current_user.groups.include?(s.owner)}
    @templates = Template.where(is_hidden: false).sort_by{|t| t.screens.count}.reverse
    respond_with(@screens)
  end

  # GET /screens/1
  # GET /screens/1.xml
  def show
    @screen = Screen.find(params[:id])
    run_callbacks :show # Run plugin hooks
    auth!
    respond_with(@screen)
  end

  # GET /screens/new
  # GET /screens/new.xml
  def new
    @screen = Screen.new(owner: current_user, locale: I18n.locale)
    auth!
    respond_with(@screen)
  end

  # GET /screens/1/edit
  def edit
    @screen = Screen.find(params[:id])
    auth!
  end

  # POST /screens
  # POST /screens.xml
  def create
    @screen = Screen.new(screen_params)

    auth!

    if @screen.save
      process_notification(@screen, {}, process_notification_options({params: {screen_name: @screen.name}}))
      run_callbacks :change # Run plugin hooks
      flash[:notice] = t(:screen_created)
    else
      @screen.clear_screen_token
      @screen.auth_action = screen_params[:auth_action]
    end

    respond_with(@screen)
  end

  # PUT /screens/1
  # PUT /screens/1.xml
  def update
    @screen = Screen.find(params[:id])

    auth!

    if @screen.update_attributes(screen_params)
      process_notification(@screen, {}, process_notification_options({params: {screen_name: @screen.name}}))

      run_callbacks :change # Run plugin hooks
      flash[:notice] = t(:screen_updated)
    end
    respond_with(@screen)
  end

  # DELETE /screens/1
  # DELETE /screens/1.xml
  def destroy
    @screen = Screen.find(params[:id])
    auth!
    process_notification(@screen, {}, process_notification_options({params: {screen_name: @screen.name}}))
    run_callbacks :destroy do
      @screen.destroy
    end

    respond_with(@screen)
  end

 def update_owners
   if params[:owner] == "User"
     @owners = User.all
   elsif params[:owner] == "Group"
     @owners = Group.all
   end
   render layout: false
 end

private

  def screen_params
    params.require(:screen).permit(:name, :location, :locale, :time_zone, :owner_id, :owner_type, :width, :height, :template_id, :is_public, :new_temp_token, :auth_action)
  end

end
