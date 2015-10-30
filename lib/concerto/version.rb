module Concerto
  module VERSION
    MAJOR = 2
    MINOR = 3
    TINY = 0
    PRE = ''
    
    STRING = [MAJOR, MINOR, TINY, PRE].reduce('') { |str,s| str + s.to_s + '.' }[0..-3]

    def self.dynamic
      Rails.cache.fetch('VERSION::dynamic') do
        `git describe --always --tags`.strip rescue ""
      end
    end
  end
end
