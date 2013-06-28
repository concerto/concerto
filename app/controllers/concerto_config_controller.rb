class ConcertoConfigController < ApplicationController

  # GET /settings
  def show
    authorize! :read, ConcertoConfig
    @concerto_configs = ConcertoConfig.where("hidden IS NULL").order(:key)

    @latest_version = VersionCheck.latest_version()
  end

  # get a hash of concerto_config keys and values and update them using the ConcertoConfig setter
  # PUT /settings
  def update
    authorize! :update, @concerto_config
    params[:concerto_config].each  do |k,v|
      ConcertoConfig.set(k,v) #only set this if the config already exists
    end
    flash[:notice] = t(:settings_saved)
    redirect_to :action => :show
  end

end
