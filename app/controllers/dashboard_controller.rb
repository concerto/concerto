class DashboardController < ApplicationController
  
  # GET /dashboard
  def index
    authorize! :read, @concerto_config
    @concerto_configs = ConcertoConfig.all
  end

  #get a hash of concerto_config keysand values and update them using the ConcertoConfig setter
  def update
    authorize! :update, @concerto_config
    params[:concerto_config].each  do |k,v|
      ConcertoConfig.set(k,v)
    end
    render :action => :index
  end
  
end
