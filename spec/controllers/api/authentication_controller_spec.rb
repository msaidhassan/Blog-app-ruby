require 'rails_helper'

RSpec.describe Api::AuthenticationController, type: :controller do
  let(:user) { create(:user, password: 'password123') }
  let(:admin) { create(:user, admin: true, password: 'password123') }

  describe 'POST /login' do
    context 'with valid credentials' do
      it 'returns user with auth token' do
        post :login, params: { email: user.email, password: 'password123' }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('token', 'exp', 'user')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized status' do
        post :login, params: { email: user.email, password: 'wrongpass' }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        post :login, params: { email: 'wrong@email.com', password: 'wrongpass' }
        expect(JSON.parse(response.body)).to include('error' => 'unauthorized')
      end
    end
  end

  describe 'POST /register' do
    let(:valid_attributes) { { name: 'Test User', email: 'test@example.com', password: 'password123' } }

    context 'with valid attributes' do
      it 'creates a new user' do
        expect {
          post :register, params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it 'returns auth token with user' do
        post :register, params: valid_attributes
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include('token', 'exp', 'user')
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors' do
        post :register, params: { email: 'invalid', password: '123' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('errors')
      end

      it 'does not create a new user' do
        expect {
          post :register, params: { email: 'invalid', password: '123' }
        }.not_to change(User, :count)
      end

      it 'returns error for duplicate email' do
        create(:user, email: 'test@example.com')
        post :register, params: valid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include('Email has already been taken')
      end
    end
  end

  describe 'POST /logout' do
    it 'returns success message' do
      request.headers['Authorization'] = "Bearer #{generate_token(user)}"
      post :logout
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('message' => 'Successfully logged out')
    end
  end

  describe 'PATCH /update_image' do
    context 'with valid image' do
      let(:image) { fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg') }

      it 'updates user image' do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        patch :update_image, params: { image: image }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('message' => 'Image updated successfully')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when no image is provided' do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        patch :update_image
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for invalid file type' do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        patch :update_image, params: { image: fixture_file_upload('spec/fixtures/test.txt', 'text/plain') }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /users/:id/image' do
    context 'when user has an image' do
      it 'redirects to image url' do
        user.image.attach(io: File.open('spec/fixtures/test_image.jpg'), filename: 'test_image.jpg', content_type: 'image/jpeg')
        get :serve_image, params: { id: user.id }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when user has no image' do
      it 'returns not found status' do
        get :serve_image, params: { id: user.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end