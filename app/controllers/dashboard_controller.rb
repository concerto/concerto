class DashboardController < ApplicationController

  # GET /dashboard/run_backup
  def run_backup
    require 'concerto-backup'
    concerto_backup()
  end

end
