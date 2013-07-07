require 'clockwork'

require './config/boot'
require './config/environment'

module Clockwork
  every(5.minutes, 'Refresh Dynamic Content') do
    DynamicContent.delay.refresh
  end
end
