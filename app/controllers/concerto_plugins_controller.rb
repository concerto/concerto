class ConcertoPluginsController < ApplicationController
  respond_to :html, :json

  # GET /concerto_plugins
  # GET /concerto_plugins.json
  def index
    authorize! :read, ConcertoPlugin
    @concerto_plugins = ConcertoPlugin.all
    respond_with(@concerto_plugins)
  end

  # GET /concerto_plugins/1
  # GET /concerto_plugins/1.json
  def show
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!
    respond_with(@concerto_plugin)
  end

  # GET /concerto_plugins/new
  # GET /concerto_plugins/new.json
  def new
    @concerto_plugin = ConcertoPlugin.new
    auth!
    respond_with(@concerto_plugin)
  end

  # GET /concerto_plugins/1/edit
  def edit
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!    
  end

  # POST /concerto_plugins
  # POST /concerto_plugins.json
  def create
    @concerto_plugin = ConcertoPlugin.new(concerto_plugin_params)
    @concerto_plugin.enabled = true
    auth!
    if @concerto_plugin.save    
      write_Gemfile()
      restart_webserver()
      flash[:notice] = t(:plugin_created)
    end
    redirect_to concerto_plugins_path
  end

  # PUT /concerto_plugins/1
  # PUT /concerto_plugins/1.json
  def update
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!
    if @concerto_plugin.update_attributes(concerto_plugin_params)
      write_Gemfile()
      flash[:notice] = t(:plugin_updated)
    end
    redirect_to concerto_plugins_path
  end

  # DELETE /concerto_plugins/1
  # DELETE /concerto_plugins/1.json
  def destroy
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!
    @concerto_plugin.destroy
    write_Gemfile()
    restart_webserver()
    redirect_to concerto_plugins_path
  end
  
  def write_Gemfile
    #slurp in the old Gemfile and write it to a backup file for use in config.ru
    old_gemfile = IO.read("Gemfile-plugins")
    File.open("Gemfile-plugins.bak", 'w') {|f| f.write(old_gemfile) }
    
    #start a big string to put the Gemfile contents in until it's written to the filesystem
    gemfile_content = ""
    ConcertoPlugin.all.each do |plugin|
      gem_args = Array.new
      gem_args << "\"#{plugin.gem_name}\""

      unless plugin.gem_version.blank?
        gem_args << "\"#{plugin.gem_version}\""
      end

      if plugin.source == "git" and not plugin.source_url.blank?
        gem_args << ":git => \"#{plugin.source_url}\""
      end

      if plugin.source == "path" and not plugin.source_url.blank?
        gem_args << ":path => \"#{plugin.source_url}\""
      end

      gemfile_content = gemfile_content + "\ngem " + gem_args.join(", ") + "\n"
    end

    File.open("Gemfile-plugins", 'w') {|f| f.write(gemfile_content) }

  end

private

  # Restrict the allowed parameters to a select set defined in the model.
  def concerto_plugin_params
    params.require(:concerto_plugin).permit(:source, :gem_name, :source_url, :enabled, :gem_version)
  end
end
