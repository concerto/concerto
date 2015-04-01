Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

require 'delayed_job'

# Before polling for new jobs we write back an update to the heartbeat tracker
# so that we can tell that DelayedJob is running.
class DelayedJobHeartbeat < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:loop) do |worker, *args, &block|
      ConcertoConfig.set(:worker_heartbeat, Clock.time.to_i)
    end
  end
end

Delayed::Worker.plugins << DelayedJobHeartbeat

# Slow DJ down to run every 15 seconds instead of 5.
Delayed::Worker.sleep_delay = 15

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"
