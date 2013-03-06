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
    begin
      pid = File.read(DELAYED_JOB_PID_PATH).strip
      Process.kill(0, pid.to_i)
      true
    rescue SystemCallError => e
      if e.class.name.start_with?('Errno::ENOENT') || e.class.name.start_with?('Errno::ESRCH')
        #if we can't find it, it's not running
        false
      elsif e.class.name.start_with?('Errno::EPERM')
        #This generally means that root own the process...probably a problem, but no need to break everything
        true
      else
        #Sod-all, let's error it out
        raise e
      end
    end
  end
  
  if ConcertoConfig[:autostart_delayed_job] == "true"
    start_delayed_job unless daemon_is_running?
  end

end
Rails.logger.debug "Completed 14-delayed_job.rb at #{Time.now.to_s}"