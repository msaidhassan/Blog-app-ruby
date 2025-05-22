require 'sidekiq'
require 'sidekiq/web'
require_relative '../../lib/admin_constraint'

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', Rails.env.development? ? 'redis://localhost:6379/0' : 'redis://redis:6379/0'),
    network_timeout: 5,
    pool_timeout: 5
  }

  config.average_scheduled_poll_interval = 15
  config.on(:startup) do
    schedule_file = Rails.root.join('config', 'recurring.yml')
    
    if File.exist?(schedule_file)
      Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', Rails.env.development? ? 'redis://localhost:6379/0' : 'redis://redis:6379/0'),
    network_timeout: 5,
    pool_timeout: 5
  }
end

# Configure Sidekiq Web UI
Sidekiq::Web.use(ActionDispatch::Cookies)
Sidekiq::Web.use(ActionDispatch::Session::CookieStore)

# Secure the Sidekiq Web UI in production
if Rails.env.production?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(username),
      ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_USERNAME'])
    ) &
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(password),
      ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_PASSWORD'])
    )
  end
end