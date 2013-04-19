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
    
  def gh_latest_version
    require 'net/https'
    require 'uri'
    require 'json'
    
    begin
      uri = URI.parse('https://api.github.com/repos/concerto/concerto/git/refs/tags')
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https" # enable SSL/TLS
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = Rails.root.join('config', 'cacert.pem').to_s
      end
      http.start {
        http.request_get(uri.path) {|res|
          @versions = Array.new
          begin
            JSON.parse(res.body).each do |tag|
              @versions << tag['ref'].gsub(/refs\/tags\//,'')
            end
          rescue TypeError
            return -1
          end
          @versions.sort! {|x,y| y <=> x }
          return @versions[0]
        }
      }
    rescue => e# if for any reason we cannot determine the version then return an error condition
      logger.error("could not determine version number at secondary location #{e.message}")
      return -1
    end
  end

end
