# Stub out a clock
class Clock
  # Wrapper around the current time.
  # Makes mocking and debugging easier because you can freeze time.
  def self.time
    Time.now
  end
end
