class DashboardController < ApplicationController
  
  # GET /dashboard
  def index
    authorize! :read, ConcertoConfig
    @concerto_configs = ConcertoConfig.all
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
