class DashboardController < ApplicationController
  before_filter :latest_version, :only => :index
  before_filter :delayed_job_running, :only => :index

  # GET /dashboard
  def index
    authorize! :read, ConcertoConfig   
    @concerto_configs = ConcertoConfig.where("hidden IS NULL")
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
