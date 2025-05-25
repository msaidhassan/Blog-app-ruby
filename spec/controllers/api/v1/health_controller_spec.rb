require 'rails_helper'

RSpec.describe Api::V1::HealthController, type: :controller do
  describe 'GET #check' do
    context 'when all services are healthy' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow_any_instance_of(Redis).to receive(:ping).and_return('PONG')
        allow(subject).to receive(:redis_connected?).and_return(true)
        allow(subject).to receive(:sidekiq_connected?).and_return(true)
      end

      it 'returns healthy status' do
        get :check

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('healthy')
        expect(json_response['checks']).to include(
          'database' => true,
          'redis' => true,
          'sidekiq' => true
        )
      end
    end

    context 'when database is down' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_raise(StandardError)
        allow_any_instance_of(Redis).to receive(:ping).and_return('PONG')
        allow(subject).to receive(:redis_connected?).and_return(true)
        allow(subject).to receive(:sidekiq_connected?).and_return(true)
      end

      it 'returns unhealthy status' do
        get :check

        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('unhealthy')
        expect(json_response['checks']['database']).to be_falsey
      end
    end

    context 'when redis is down' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow_any_instance_of(Redis).to receive(:ping).and_raise(Redis::CannotConnectError)
        allow(subject).to receive(:redis_connected?).and_return(false)
        allow(subject).to receive(:sidekiq_connected?).and_return(false)
      end

      it 'returns unhealthy status' do
        get :check

        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('unhealthy')
        expect(json_response['checks']['redis']).to be_falsey
        expect(json_response['checks']['sidekiq']).to be_falsey
      end
    end

    context 'when sidekiq is down' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow_any_instance_of(Redis).to receive(:ping).and_return('PONG')
        allow(subject).to receive(:redis_connected?).and_return(true)
        allow(subject).to receive(:sidekiq_connected?).and_return(false)
      end

      it 'returns unhealthy status' do
        get :check

        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('unhealthy')
        expect(json_response['checks']['sidekiq']).to be_falsey
      end
    end
  end
end