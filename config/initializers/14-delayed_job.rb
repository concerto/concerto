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
    require 'fileutils'
    #be sure to recursively create the path needed - mkdir won't do it
    FileUtils.mkdir_p "#{Rails.root}/tmp/pids/" unless File.exists?("#{Rails.root}/tmp/pids/")
    pid = File.read("#{Rails.root}/tmp/pids/delayed_job.pid")
    (pid.nil?) ? (return false) : pid.strip!
    Process.kill(0, pid.to_i)
    true
  rescue Errno::ENOENT, Errno::ESRCH
    false
  rescue Errno::EPERM
    true
    Rails.logger.error "Concerto does not have access to the delayed_job process."
  end
  
  start_delayed_job unless daemon_is_running?

end
Rails.logger.debug "Completed 14-delayed_job.rb at #{Time.now.to_s}"
