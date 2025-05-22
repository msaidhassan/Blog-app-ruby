redis_config = {
  url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0'),
  network_timeout: 5,
  connect_timeout: 5,
  error_handler: -> (method:, returning:, exception:) {
    Rails.logger.error "Redis Cache Error: #{exception.class} - #{exception.message}"
    Raven.capture_exception(exception) if defined?(Raven)
  }
}

Rails.application.config.cache_store = :redis_cache_store, redis_config