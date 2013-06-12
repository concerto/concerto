def pid_process_running?(pidfile)
  pidfile = "#{Rails.root}/tmp/pids/delayed_job.pid"
  if File.exist?(pidfile)
    pid = File.read(pidfile).strip.to_i
    begin
      Process.getpgid(pid)
      true
    rescue Errno::ESRCH
      false
    end
  end
end