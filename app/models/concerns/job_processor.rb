module JobProcessor
  extend ActiveSupport::Concern

  included do
    before_perform :track_start
    after_perform :track_success
    
    private

    def track_start
      Rails.logger.info("Starting job #{self.class.name} with arguments: #{arguments.inspect}")
      Rails.cache.increment("jobs:#{self.class.name}:started")
    end

    def track_success
      Rails.logger.info("Successfully completed job #{self.class.name}")
      Rails.cache.increment("jobs:#{self.class.name}:completed")
    end

    
  end
end