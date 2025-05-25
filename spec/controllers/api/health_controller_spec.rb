require 'rails_helper'

RSpec.describe Api::HealthController, type: :controller do
  describe 'GET /health/check' do
    context 'when all services are healthy' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow_any_instance_of(Redis).to receive(:ping).and_return('PONG')
        allow(controller).to receive(:`).with('ps aux | grep -i [s]idekiq').and_return('sidekiq process')
      end

      it 'returns healthy status' do
        get :check
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include(
          'status' => 'healthy',
          'checks' => {
            'database' => true,
            'redis' => true,
            'sidekiq' => true
          }
        )
      end
    end

    context 'when database is down' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_raise(StandardError)
        allow_any_instance_of(Redis).to receive(:ping).and_return('PONG')
        allow(controller).to receive(:`).with('ps aux | grep -i [s]idekiq').and_return('sidekiq process')
      end

      it 'returns unhealthy status' do
        get :check
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)['checks']['database']).to be false
      end
    end

    context 'when redis is down' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow_any_instance_of(Redis).to receive(:ping).and_raise(Redis::CannotConnectError)
        allow(controller).to receive(:`).with('ps aux | grep -i [s]idekiq').and_return('sidekiq process')
      end

      it 'returns unhealthy status' do
        get :check
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)['checks']['redis']).to be false
      end
    end

    context 'when sidekiq is down' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow_any_instance_of(Redis).to receive(:ping).and_return('PONG')
        allow(controller).to receive(:`).with('ps aux | grep -i [s]idekiq').and_return('')
      end

      it 'returns unhealthy status' do
        get :check
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)['checks']['sidekiq']).to be false
      end
    end
  end
end