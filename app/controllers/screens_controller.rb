class ScreensController < ApplicationController
  # GET /screens
  # GET /screens.xml
  def index
    @screens = Screen.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @screens }
    end
  end

  # GET /screens/1
  # GET /screens/1.xml
  def show
    @screen = Screen.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @screen }
    end
  end

  # GET /screens/new
  # GET /screens/new.xml
  def new
    @screen = Screen.new
    @templates = Template.all
    @users = User.all
    @groups = Group.all
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @screen }
    end
  end

  # GET /screens/1/edit
  def edit
    @screen = Screen.find(params[:id])
    @template = Template.new
    
    @templates = Template.all
    #@templates_bestfit = Template.find(:all, :conditions => "width / height = #{screen_aspect_ratio}")
    #@templates_other = Template.find(:all, :conditions => "width / height != #{screen.aspect_ratio}")
    @users = User.all
    @groups = Group.all
  end

  # POST /screens
  # POST /screens.xml
  def create
    @screen = Screen.new(params[:screen])
    @templates = Template.all
    @users = User.all
    @groups = Group.all

    # Process the owner into something that makes sense
    owner = params[:owner].split('-')
    if Screen::SCREEN_OWNER_TYPES.include?(owner[0])
      @screen.owner_type = owner[0]
      @screen.owner_id = owner[1]
    end
       
    
    respond_to do |format|
      if @screen.save
        format.html { redirect_to(@screen, :notice => t(:position_created)) }
        format.xml  { render :xml => @screen, :status => :created, :location => @screen }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @screen.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /screens/1
  # PUT /screens/1.xml
  def update
    @screen = Screen.find(params[:id])
    @templates = Template.all
    @users = User.all
    @groups = Group.all

    # Process the owner into something that makes sense
    owner = params[:owner].split('-')
    if Screen::SCREEN_OWNER_TYPES.include?(owner[0])
      @screen.owner_type = owner[0]   
      @screen.owner_id = owner[1] 
    end

    respond_to do |format|
      if @screen.update_attributes(params[:screen])
        format.html { redirect_to(@screen, :notice => t(:screen_updated)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @screen.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /screens/1
  # DELETE /screens/1.xml
  def destroy
    @screen = Screen.find(params[:id])
    @screen.destroy

    respond_to do |format|
      format.html { redirect_to(screens_url) }
      format.xml  { head :ok }
    end
  end
  
 def update_owners
   if params[:owner] == "User"
     @owners = User.all
   elsif params[:owner] == "Group"
     @owners = Group.all
   end
   render :layout => false
 end
 
end
