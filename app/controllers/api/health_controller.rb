module Api
  class HealthController < ApplicationController
    skip_before_action :authenticate_request

    def check
      status = {
        database: database_connected?,
        redis: redis_connected?,
        sidekiq: sidekiq_connected?
      }

      if status.values.all?
        render json: { status: 'healthy', checks: status }
      else
        render json: { status: 'unhealthy', checks: status }, status: :service_unavailable
      end
    end

    private

    def database_connected?
      ActiveRecord::Base.connection.active?
    rescue StandardError
      false
    end

    def redis_connected?
      Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')).ping == 'PONG'
    rescue StandardError
      false
    end

    def sidekiq_connected?
      return false unless redis_connected?
      `ps aux | grep -i [s]idekiq`.present?
    rescue StandardError
      false
    end
  end
end