module JobErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from(StandardError) do |exception|
      Rails.logger.error "Job Error (#{self.class.name}): #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n")
      raise exception
    end
  end
end