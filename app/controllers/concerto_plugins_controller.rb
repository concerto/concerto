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
    @gemspec = Gem.loaded_specs[@concerto_plugin.gem_name]
    auth!
    @rubygems_current_version = rubygems_current_version(@concerto_plugin)
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
      process_plugin_notification
      #if boot.rb found a "frozen" bundler environment, don't try to write the Gemfile or bundle install
      if ENV['FROZEN'] == "1"
        flash[:notice] = t(:plugin_created_frozen_env)
      else
        write_Gemfile()
        restarted = restart_webserver()
      end
      if restarted
        flash[:notice] = t(:plugin_created)
      end
      redirect_to concerto_plugins_path
    else
      respond_with(@concerto_plugin)
    end
  end

  # PUT /concerto_plugins/1
  # PUT /concerto_plugins/1.json
  def update
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!
    if @concerto_plugin.update_attributes(concerto_plugin_params)
      process_plugin_notification
      if ENV['FROZEN'] == "1"
        flash[:notice] = t :plugin_updated_frozen_env
      else
        write_Gemfile
        flash[:notice] = t(:plugin_updated)
      end
      redirect_to concerto_plugins_path
    else
      respond_with(@concerto_plugin)
    end
  end

  def process_plugin_notification
    process_notification(@content, {}, process_notification_options({
      params: {
        concerto_plugin_gem_name: @concerto_plugin.gem_name
      }
    }))
  end

  # DELETE /concerto_plugins/1
  # DELETE /concerto_plugins/1.json
  def destroy
    @concerto_plugin = ConcertoPlugin.find(params[:id])
    auth!

    process_plugin_notification
    @concerto_plugin.destroy
    if ENV['FROZEN'] == "1"
      flash[:notice] = t(:plugin_removed_frozen_env)
    else
      write_Gemfile()
      restarted = restart_webserver()
    end
    if restarted
      flash[:notice] = t(:plugin_removed)
    end
    redirect_to concerto_plugins_path
  end

  def update_gem
    plugin = ConcertoPlugin.find(params[:id])
    system("bundle update #{plugin.gem_name}")
    restarted = restart_webserver()
    if restarted
      flash[:notice] = t(:plugin_updated)
    end
    redirect_to action: :show, id: plugin.id
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
        gem_args << "git: \"#{plugin.source_url}\""
      end

      if plugin.source == "path" and not plugin.source_url.blank?
        gem_args << "path: \"#{plugin.source_url}\""
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

  def rubygems_current_version(concerto_plugin)
    version = nil
    begin
      require 'open-uri'
      version = JSON.load(open("https://rubygems.org/api/v1/versions/#{concerto_plugin.gem_name}.json")).first['number']
    rescue Exception => e
      Rails.logger.debug("Unable to determine current rubygems version for #{concerto_plugin.gem_name} - #{e.message}")
    end

    version
  end
end
