require 'rails_helper'

RSpec.describe Api::V1::AuthenticationController, type: :controller do
  let(:user) { create(:user, password: 'password123') }
  let(:admin) { create(:user, admin: true, password: 'password123') }

  describe 'POST #login' do
    context 'with valid credentials' do
      it 'returns authentication token' do
        post :login, params: { email: user.email, password: 'password123' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to include('token', 'exp', 'user')
        expect(json_response['user']['email']).to eq(user.email)
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for wrong password' do
        post :login, params: { email: user.email, password: 'wrongpass' }
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('unauthorized')
      end

      it 'returns unauthorized for non-existent email' do
        post :login, params: { email: 'nonexistent@example.com', password: 'password123' }
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('unauthorized')
      end
    end
  end

  describe 'POST #register' do
    let(:valid_params) do
      {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user and returns token' do
        expect {
          post :register, params: valid_params
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response).to include('token', 'exp', 'user')
        expect(json_response['user']['email']).to eq('john@example.com')
      end

      it 'creates a user with image' do
        image = fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg')
        expect {
          post :register, params: valid_params.merge(image: image)
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(User.last.image).to be_attached
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing required fields' do
        post :register, params: { email: 'john@example.com' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include(/Name can't be blank/)
      end

      it 'returns error for invalid email format' do
        post :register, params: valid_params.merge(email: 'invalid-email')
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include(/Email is invalid/)
      end

      it 'returns error for duplicate email' do
        existing_user = create(:user)
        post :register, params: valid_params.merge(email: existing_user.email)
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include(/Email has already been taken/)
      end
    end
  end

  describe 'POST #logout' do
    it 'returns success message' do
      request.headers['Authorization'] = "Bearer #{jwt_encode(user_id: user.id)}"
      post :logout
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('Successfully logged out')
    end
  end

  describe 'PATCH #update_image' do
    before { request.headers['Authorization'] = "Bearer #{jwt_encode(user_id: user.id)}" }

    context 'with valid image' do
      it 'updates user image' do
        image = fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg')
        patch :update_image, params: { image: image }
        
        expect(response).to have_http_status(:ok)
        expect(user.reload.image).to be_attached
      end
    end

    context 'with invalid image' do
      it 'returns error when no image is provided' do
        patch :update_image
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Image must be add')
      end

      it 'returns error for invalid image type' do
        image = fixture_file_upload('spec/fixtures/test.txt', 'text/plain')
        patch :update_image, params: { image: image }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('Image must be a JPEG, PNG, or GIF')
      end
    end
  end

  describe 'GET #serve_image' do
    context 'when image exists' do
      it 'redirects to image url' do
        image = fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg')
        user.image.attach(image)
        
        get :serve_image, params: { id: user.id }
        
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when image does not exist' do
      it 'returns not found error' do
        get :serve_image, params: { id: user.id }
        
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('No image attached')
      end
    end
  end
end