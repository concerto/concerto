class ToolsController < ApplicationController

  # GET /tools/run_backup
  def run_backup
    require 'concerto-backup'
    concerto_backup()
  end

end
