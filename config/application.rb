require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module BlogApp
  class Application < Rails::Application
    config.load_defaults 8.0
    
    # API-only application
    config.api_only = true

    # Autoload lib directory
    config.autoload_paths << Rails.root.join('lib')

    # Use Sidekiq as the job processor
    config.active_job.queue_adapter = :sidekiq

    # Configure session middleware for API
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore

    # Enable Active Storage
    config.active_storage.variant_processor = :mini_magick

    # Configure time zone
    config.time_zone = 'UTC'
    config.active_record.default_timezone = :utc

    # Configure generators
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end
  end
end
