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
end
