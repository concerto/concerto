Rails.logger.debug "Starting 14-delayed_job.rb at #{Time.now.to_s}"

#NB: This code will not work if more than one worker process is being used
#Additionally, the -m argument can be used to spawn a monitor process alongside the daemon(s)
unless Rails.env.test?
  DELAYED_JOB_PID_PATH = "#{Rails.root}/tmp/pids/delayed_job.pid"
  
  def start_delayed_job
    Thread.new do 
      `ruby script/delayed_job start`
    end
  end
  
  def daemon_is_running?
    pid = File.read(DELAYED_JOB_PID_PATH).strip
    Process.kill(0, pid.to_i)
    true
  rescue Errno::ENOENT, Errno::ESRCH   # file or process not found
    false
  end
  
  if ConcertoConfig[:autostart_delayed_job] == "true"
    start_delayed_job unless daemon_is_running?
  end

end
Rails.logger.debug "Completed 14-delayed_job.rb at #{Time.now.to_s}"