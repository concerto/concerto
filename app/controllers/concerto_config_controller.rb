class ConcertoConfigController < ApplicationController

  # GET /settings
  def show
    authorize! :read, ConcertoConfig
    @concerto_configs = ConcertoConfig.where("hidden IS NULL").order('"group", seq_no, "key"')
  end

  # get a hash of concerto_config keys and values and update them using the ConcertoConfig setter
  # PUT /settings
  def update
    authorize! :update, @concerto_config
    params[:concerto_config].each  do |k,v|
      config = ConcertoConfig.where(:key => k).first
      if config.nil?
        config = ConcertoConfig.new(:key => k, :value => v)
        config.save
      else
        config.update_column(:value, v)
      end
    end

    ConcertoConfig.cache_expire
    flash[:notice] = t(:settings_saved)
    redirect_to :action => :show
  end

end
