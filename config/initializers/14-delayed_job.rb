Rails.logger.debug "Starting 14-delayed_job.rb at #{Time.now.to_s}"

#NB: This code will not work if more than one worker process is being used
#Additionally, the -m argument can be used to spawn a monitor process alongside the daemon(s)
unless Rails.env.test?
  
  def start_delayed_job
    Thread.new do 
      `ruby script/delayed_job start`
    end
  end
  
  def daemon_is_running?
    FileTest.exists?(Rails.root + "/tmp/pids/delayed_job.pid")
  end
  
  if ConcertoConfig[:autostart_delayed_job] == "true"
    unless daemon_is_running?
      start_delayed_job 
    end
  end

end
Rails.logger.debug "Completed 14-delayed_job.rb at #{Time.now.to_s}"