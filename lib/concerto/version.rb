module Concerto
  module VERSION
    MAJOR = 0
    MINOR = 6
    TINY = 0
    PRE = 'hotelhummingbird'

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
    
    def self.dynamic
      `git describe --always --tags`.strip rescue ""
    end
  end
end
