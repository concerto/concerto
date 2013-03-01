class ConcertoPluginsController < ApplicationController
  before_filter :latest_version, only: [:index, :show, :new, :edit]
  before_filter :delayed_job_running, only: [:index, :show, :new, :edit]

  # GET /concerto_plugins
  # GET /concerto_plugins.json
  def index
    @concerto_plugins = ConcertoPlugin.all
    auth!(allow_empty: false)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @concerto_plugins }
    end
  end

  # GET /concerto_plugins/1
  # GET /concerto_plugins/1.json
  def show
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @concerto_plugin }
    end
  end

  # GET /concerto_plugins/new
  # GET /concerto_plugins/new.json
  def new
    @concerto_plugin = ConcertoPlugin.new
    auth!
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @concerto_plugin }
    end
  end

  # GET /concerto_plugins/1/edit
  def edit
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!    
  end

  # POST /concerto_plugins
  # POST /concerto_plugins.json
  def create
    @concerto_plugin = ConcertoPlugin.new(params[:concerto_plugin])
    auth!
    #if we're creating the plugin, install and enabled it by default
    respond_to do |format|
      if @concerto_plugin.save    
        write_Gemfile()
        format.html { redirect_to @concerto_plugin, notice: 'Concerto plugin was successfully created.' }
        format.json { render json: @concerto_plugin, status: :created, location: @concerto_plugin }
      else
        format.html { render action: "new" }
        format.json { render json: @concerto_plugin.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /concerto_plugins/1
  # PUT /concerto_plugins/1.json
  def update
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!
    respond_to do |format|
      if @concerto_plugin.update_attributes(params[:concerto_plugin])
        write_Gemfile()
        format.html { redirect_to @concerto_plugin, notice: 'Concerto plugin was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @concerto_plugin.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /concerto_plugins/1
  # DELETE /concerto_plugins/1.json
  def destroy
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!
    @concerto_plugin.destroy
    write_Gemfile()
    respond_to do |format|
      format.html { redirect_to concerto_plugins_url }
      format.json { head :no_content }
    end
  end
  
  def write_Gemfile
    #start a big string to put the Gemfile contents in until it's written to the filesystem
    gemfile_content = ""
    ConcertoPlugin.all.each do |plugin|
      gem_args = Array.new
      gem_args << "\"#{plugin.gem_name}\""

      unless plugin.gem_version.blank?
        gem_args << "\"#{plugin.gem_version}\""
      end

      if plugin.source == "git" and not plugin.source_url.blank?
        gem_args << "git: \"#{plugin.source_url}\""
      end

      if plugin.source == "path" and not plugin.source_url.blank?
        gem_args << "path: \"#{plugin.source_url}\""
      end

      gemfile_content = gemfile_content + "\ngem " + gem_args.join(", ") + "\n"
    end

    File.open("Gemfile-plugins", 'w') {|f| f.write(gemfile_content) }

    #Going to try a synchronous bundle install - though this could get ugly and slow
    #The alternative is to use spawn with a timout protection (using the timeout Ruby module
    #Fork may not be used here as it's not cross-platform implemented
    bundle_status = system("bundle install")
    if bundle_status == true
      File.open("tmp/restart.txt", "w") {}
    else
      raise "An error occurred while running bundle install."
    end
  end
  
end
