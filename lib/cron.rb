require 'clockwork'

require './config/boot'
require './config/environment'

module Clockwork

  Clockwork.configure do |config|
    config[:sleep_timeout] = 5      # seconds
  end

  every(5.minutes, 'Refresh Dynamic Content') do
    DynamicContent.delay.refresh
  end

  every(5.minutes, 'Remove Abandoned Previews') do
    Media.delay.cleanup_previews
  end

  every(1.day, 'Deny Expired Content Submissions') do
    Submission.delay.deny_old_expired
  end
  
  if RUBY_VERSION >= "1.9"  
    every(1.day, 'Remove old public activity entries') do  
      unless ConcertoConfig[:keep_activity_log].to_i == 0
        activities =  PublicActivity::Activity.where("created_at > :days", {:days => ConcertoConfig[:keep_activity_log].to_i.days.ago}).destroy_all
      end
    end  
  end

end


