def pid_process_running?(pidfile)
  pidfile = "#{Rails.root}/tmp/pids/delayed_job.pid"
  if File.exist?(pidfile)
    pid = File.read(pidfile)
    (pid.nil?) ? (return false) : pid.strip!
    begin
      Process.kill(0, pid.to_i)
      true #if we arrive here, the process received the 0 signal and it's OK
    rescue Errno::ENOENT, Errno::ESRCH
      false #no process found
    rescue Errno::EPERM
      Rails.logger.error "Concerto does not have access to the delayed_job process."
      true
    end
  else
    false #pidfile doesn't even exist
  end
end