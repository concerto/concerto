module Concerto
  module VERSION
    MAJOR = 2
    MINOR = 3
    PATCH = 7
    PRE = "beta.1"
    BUILD = nil

    # https://semver.org/
    STRING = [[[MAJOR, MINOR, PATCH].compact.join('.'), PRE].compact.join('-'), BUILD].compact.join('+')

    def self.dynamic
      Rails.cache.fetch('VERSION::dynamic') do
        `git describe --always --tags`.strip rescue ""
      end
    end
  end
end
