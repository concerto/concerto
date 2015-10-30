# Check the latest version of Concerto 2 via remote sources.
module VersionCheck
  def self.latest_version
    begin
      version = Rails.cache.read 'concerto_version'
      version_updated = Rails.cache.read 'concerto_version_time'
      if !version.nil? && version_updated.is_a?(Time) && !version_updated.nil? # Version is cached.
        if version_updated < Time.now - 86400 # Stale (older than 24 hours).
          version = Octokit.latest_release('concerto/concerto').tag_name
        end
      else # Fetch the latest version.
        Rails.logger.info 'Downloading latest Concerto version information for the first time.'
        version = Octokit.latest_release('concerto/concerto').tag_name
      end
      return version
    rescue Octokit::TooManyRequests => e
      Rails.logger.error 'Exceeded Github API quota when trying to fetch Concerto version.'
      return Concerto::VERSION::STRING
    end
  end
end
