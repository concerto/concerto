Rails.logger.debug "Starting 14-delayed_job.rb at #{Time.now.to_s}"

#NB: This code will not work if more than one worker process is being used
#Additionally, the -m argument can be used to spawn a monitor process alongside the daemon(s)
unless Rails.env.test?  
  require 'process_tools' 
  if !pid_process_running?("#{Rails.root}/tmp/pids/delayed_job.pid")
    require 'fileutils'
    #be sure to recursively create the path needed - mkdir won't do it
    FileUtils.mkdir_p "#{Rails.root}/tmp/pids/" unless File.exists?("#{Rails.root}/tmp/pids/")  
    Thread.new do 
      `ruby script/delayed_job start`
    end
  end

end
Rails.logger.debug "Completed 14-delayed_job.rb at #{Time.now.to_s}"
