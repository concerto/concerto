module Concerto
  module VERSION
    MAJOR = 2
    MINOR = 0
    TINY = 0
    PRE = ''

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
    
    def self.dynamic
      Rails.cache.fetch('VERSION::dynamic') do
        `git describe --always --tags`.strip rescue ""
      end
    end
  end
end
