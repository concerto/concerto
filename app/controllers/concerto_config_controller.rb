class ConcertoConfigController < ApplicationController

  # GET /settings
  def show
    authorize! :read, ConcertoConfig
    # The ordering is by group, falling back to the id (being the original order in which it was added to the db)
    @concerto_configs = ConcertoConfig.where("hidden IS NULL").order('"group", "key", "id"')
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
    
    #remove any config items not in the whitelist on the ConcertoConfig class
    ConcertoConfig.all.each do |c|   
      unless ConcertoConfig::CONFIG_ITEMS.include?(c.key)
        c.destroy
      end
    end
    
    ConcertoConfig.cache_expire
    flash[:notice] = t(:settings_saved)
    redirect_to :action => :show
  end

end
