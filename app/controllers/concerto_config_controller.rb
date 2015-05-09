class ConcertoConfigController < ApplicationController

  # GET /settings
  def show
    authorize! :read, ConcertoConfig
    @concerto_configs = ConcertoConfig.where(hidden: false).order("category, seq_no, concerto_configs.key")
  end

  def initiate_restart
    restart_webserver()
    redirect_to action: :show
  end

  def config_check
    @imagemagick_installed = command?("convert")
    @rmagick_installed = Gem::Specification::find_all_by_name('rmagick').any?
    @not_using_sqlite = ActiveRecord::Base.configurations[Rails.env]['adapter'] != "sqlite3"
    @not_world_writable = !(File.stat(Rails.root).world_writable?)
    #Using Ruby methods to stat a directory and convert the mod bit to the familiar 3-digit octal
    #The logic here and in the view assumes a *nix system - no idea what other posix systems will return
    @rails_root_perms = File.stat(Rails.root).mode.to_s(8)[-3,3] == "700" #should be 700 on a shared box
    @rails_log_perms = File.stat(Rails.root.join('log')).mode.to_s(8)[-3,3] == "600" #should be 600 on a shared box
    @rails_tmp_perms = File.stat(Rails.root.join('tmp')).writable?
    @webserver_ownership = File.stat(Rails.root).owned?
  end

  # get a hash of concerto_config keys and values and update them using the ConcertoConfig setter
  # PUT /settings
  def update
    authorize! :update, ConcertoConfig
    params[:concerto_config].each  do |k,v|
      config = ConcertoConfig.where(key: k).first
      # since all they can change is the value, only create/update if it changed
      if config.nil? || config.value != v
        if config.nil?
          config = ConcertoConfig.new(key: k, value: v)
          config.save
        else
          config.update_column(:value, v)
        end
        process_notification(config, {}, process_notification_options({params: {concerto_config_key: config.key}}))
      end
    end

    ConcertoConfig.cache_expire
    flash[:notice] = t(:settings_saved)
    redirect_to action: :show
  end

end
