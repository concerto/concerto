class ScreensController < ApplicationController
  # Define integration hooks for Concerto Plugins
  define_callbacks :show # controller callback for 'show' action
  ConcertoPlugin.install_callbacks(self) # Get the callbacks from plugins
  respond_to :html, :json, :xml

  # GET /screens
  # GET /screens.xml
  def index
    @screens = Screen.all
    @my_screens = []
    if !current_user.nil?
      my_group_screens = current_user.groups.collect{ |g| g.screens }.flatten
      my_screens = current_user.screens
      @my_screens = my_group_screens + my_screens
    end
    auth!

    # The screen index has a sidebar that shows all templates.
    @templates = Template.where(:is_hidden => false).sort_by{|t| t.screens.count}

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
    @screen = Screen.new(:owner => current_user)
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
    # Process the owner into something that makes sense
    owner = params[:owner].split('-')
    if Screen::SCREEN_OWNER_TYPES.include?(owner[0])
      @screen.owner_type = owner[0]
      @screen.owner_id = owner[1]
    end
    auth!
    
    if @screen.save
      process_notification(@screen, {:public_owner => current_user.id}, :action => 'create')
      flash[:notice] = t(:screen_created)
    end
    
    respond_with(@screen)
  end

  # PUT /screens/1
  # PUT /screens/1.xml
  def update
    @screen = Screen.find(params[:id])
    
    # Process the owner into something that makes sense
    owner = params[:owner].split('-')
    if Screen::SCREEN_OWNER_TYPES.include?(owner[0])
      @screen.owner_type = owner[0]
      @screen.owner_id = owner[1]
    end
    auth!
    
    if @screen.update_attributes(screen_params)
      flash[:notice] = t(:screen_updated)
    end
    respond_with(@screen)
  end

  # DELETE /screens/1
  # DELETE /screens/1.xml
  def destroy
    @screen = Screen.find(params[:id])
    auth!
    process_notification(@screen, {:public_owner => current_user.id, :screen_name => @screen.name}, :action => 'destroy')
    @screen.destroy

    respond_with(@screen)
  end
  
 def update_owners
   if params[:owner] == "User"
     @owners = User.all
   elsif params[:owner] == "Group"
     @owners = Group.all
   end
   render :layout => false
 end

private

  def screen_params
    params.require(:screen).permit(:name, :location, :owner, :width, :height, :template_id, :is_public, :new_temp_token, :auth_action)
  end
 
end
