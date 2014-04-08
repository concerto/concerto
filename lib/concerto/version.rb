module Concerto
  module VERSION
    MAJOR = 0
    MINOR = 9
    TINY = 0
    PRE = 'kilobalrog'

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
    
    def self.dynamic
      Rails.cache.fetch('VERSION::dynamic') do
        `git describe --always --tags`.strip rescue ""
      end
    end
  end
end
