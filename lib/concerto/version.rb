module Concerto
  module VERSION
    MAJOR = 2
    MINOR = 3
    TINY = 4
    PRE = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')

    def self.dynamic
      Rails.cache.fetch('VERSION::dynamic') do
        `git describe --always --tags`.strip rescue ""
      end
    end
  end
end
