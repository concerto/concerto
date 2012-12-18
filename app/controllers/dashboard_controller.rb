class DashboardController < ApplicationController
  #includes for system status functions
  require 'sys/proctable'
  include Sys  
  
  # GET /dashboard
  def index
    authorize! :read, ConcertoConfig

    @delayed_job_running = false
    ProcTable.ps do |process|
      if process.cmdline.strip == "delayed_job" && process.state.strip == "run"
        @delayed_job_running = true
      end
    end
      
    @concerto_configs = ConcertoConfig.where("hidden IS NULL")
  end

  #get a hash of concerto_config keys and values and update them using the ConcertoConfig setter
  def update
    authorize! :update, @concerto_config
    params[:concerto_config].each  do |k,v|
      ConcertoConfig.set(k,v) #only set this if the config already exists
    end
    render :action => :index
  end
  
end
