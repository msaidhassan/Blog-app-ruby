require 'rails_helper'

RSpec.describe Api::V1::AuthenticationController, type: :controller do
  describe 'POST #login' do
    let(:user) { create(:user, password: 'password123') }

    context 'with valid credentials' do
      it 'returns a JWT token' do
        post :login, params: { email: user.email, password: 'password123' }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('token')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized status' do
        post :login, params: { email: user.email, password: 'wrongpassword' }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #register' do
    let(:valid_attributes) do
      {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user and returns a token' do
        expect {
          post :register, params: valid_attributes
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include('token')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a user' do
        expect {
          post :register, params: valid_attributes.merge(email: '')
        }.not_to change(User, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with duplicate email' do
      before { create(:user, email: 'john@example.com') }

      it 'does not create a user' do
        expect {
          post :register, params: valid_attributes
        }.not_to change(User, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end