module Concerto
  module VERSION
    MAJOR = 0
    MINOR = 7
    TINY = 0
    PRE = 'indiaibex'

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
    
    def self.dynamic
      `git describe --always --tags`.strip rescue ""
    end
  end
end
