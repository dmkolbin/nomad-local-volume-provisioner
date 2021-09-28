module RetryHelper
  RETRIES_DELAY = 3
  RETRIES_COUNT = 3

  def with_retry(exceptions: [StandardError], retries_delay: RETRIES_DELAY, retries_count: RETRIES_COUNT)
    retries ||= 0
    sleep retries_delay if retries.positive?

    yield
  rescue Exception => error
    if exceptions.any? { |ex| error.is_a?(Class) && ex >= error || ex === error }
      if (retries += 1) < retries_count
        $log.warn("Attempt # #{retries} is failed\n  #{error}")

        retry
      end
    end

    raise error
  end
end
