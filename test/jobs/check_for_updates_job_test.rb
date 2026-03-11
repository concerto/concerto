require "test_helper"

class CheckForUpdatesJobTest < ActiveJob::TestCase
  test "writes release info to cache when fetch succeeds" do
    release = { tag: "3.1.0", url: "https://github.com/concerto/concerto/releases/tag/v3.1.0" }
    UpdateChecker.stub(:fetch_from_github, release) do
      mock_cache = Minitest::Mock.new
      mock_cache.expect(:write, true) do |key, value, **opts|
        key == UpdateChecker::CACHE_KEY &&
          value == release &&
          opts[:expires_in] == UpdateChecker::CACHE_TTL
      end
      Rails.stub(:cache, mock_cache) do
        CheckForUpdatesJob.perform_now
      end
      assert mock_cache.verify
    end
  end

  test "writes nil to cache when fetch fails" do
    UpdateChecker.stub(:fetch_from_github, nil) do
      mock_cache = Minitest::Mock.new
      mock_cache.expect(:write, true) do |key, value, **opts|
        key == UpdateChecker::CACHE_KEY &&
          value.nil? &&
          opts[:expires_in] == UpdateChecker::CACHE_TTL
      end
      Rails.stub(:cache, mock_cache) do
        CheckForUpdatesJob.perform_now
      end
      assert mock_cache.verify
    end
  end
end
