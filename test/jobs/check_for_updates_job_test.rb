require "test_helper"

class CheckForUpdatesJobTest < ActiveJob::TestCase
  test "calls warm_cache on UpdateChecker" do
    warm_cache_called = false
    UpdateChecker.stub(:warm_cache, -> { warm_cache_called = true }) do
      CheckForUpdatesJob.perform_now
    end
    assert warm_cache_called
  end
end
