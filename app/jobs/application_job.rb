class ApplicationJob < ActiveJob::Base
  include JobErrorHandler

  # Automatically retry jobs that encountered a deadlock or similar issues
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError
  
  # Add custom handling for job timeouts
  around_perform do |job, block|
    Timeout.timeout(30.minutes) do
      block.call
    end
  rescue Timeout::Error
    Rails.logger.error "Job Timeout (#{job.class.name})"
    raise
  end
end
