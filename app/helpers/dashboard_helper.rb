module DashboardHelper  
  # Check if the background processor is running or not
  # by looking at it's heartbeat and comparing it to a threshold.
  def background_processor_running?
    last_update = ConcertoConfig[:worker_heartbeat]
    threshold = Delayed::Worker.sleep_delay * 4
    return (Clock.time.to_i - last_update.to_i) < threshold
  end
end
