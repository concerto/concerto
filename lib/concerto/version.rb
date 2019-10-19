module Concerto
  module VERSION
    MAJOR = 2
    MINOR = 4
    PATCH = 0
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
