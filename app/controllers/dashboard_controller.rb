class DashboardController < ApplicationController

  # GET /dashboard
  def index
    authorize! :read, ConcertoConfig
    # The ordering is by group, sequence number (if specified), name (if specified),
    # falling back to the id (being the original order in which it was added to the db)
    # if the developer omits the seq_no or name.
    @concerto_configs = ConcertoConfig.where("hidden IS NULL").order('"group", seq_no, name, id')

    @latest_version = VersionCheck.latest_version()
  end

  # get a hash of concerto_config keys and values and update them using the ConcertoConfig setter
  # POST /dashboard/update
  def update
    authorize! :update, @concerto_config
    params[:concerto_config].each  do |k,v|
      ConcertoConfig.set(k,v) #only set this if the config already exists
    end
    flash[:notice] = t(:settings_saved)
    redirect_to :action => :index
  end

  # GET /dashboard/run_backup
  def run_backup
    require 'concerto-backup'
    concerto_backup()
  end

end
