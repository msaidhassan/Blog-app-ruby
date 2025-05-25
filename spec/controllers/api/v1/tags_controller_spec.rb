require 'rails_helper'

RSpec.describe Api::V1::TagsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:token) { jwt_encode(user_id: user.id) }
  let(:admin_token) { jwt_encode(user_id: admin.id) }

  describe 'GET #index' do
    before do
      request.headers['Authorization'] = "Bearer #{token}"
      create_list(:tag, 3)
    end

    it 'returns all tags' do
      get :index
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(3)
    end
  end

  describe 'GET #show' do
    let(:tag) { create(:tag) }

    before do
      request.headers['Authorization'] = "Bearer #{token}"
    end

    context 'when tag exists' do
      before { create_list(:post, 2, tags: [tag]) }

      it 'returns tag with associated posts' do
        get :show, params: { id: tag.id }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(tag.id)
        expect(json_response['posts'].length).to eq(2)
        expect(json_response['posts'].first).to include('user')
      end
    end

    context 'when tag does not exist' do
      it 'returns not found' do
        get :show, params: { id: -1 }
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) { { tag: { name: 'ruby' } } }

    before do
      request.headers['Authorization'] = "Bearer #{token}"
    end

    context 'with valid parameters' do
      it 'creates a new tag' do
        expect {
          post :create, params: valid_attributes
        }.to change(Tag, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['name']).to eq('ruby')
      end

      it 'converts tag name to lowercase' do
        post :create, params: { tag: { name: 'RUBY' } }
        
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['name']).to eq('ruby')
      end
    end

    context 'with invalid parameters' do
      it 'does not create tag without name' do
        expect {
          post :create, params: { tag: { name: '' } }
        }.not_to change(Tag, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create duplicate tag' do
        create(:tag, name: 'ruby')
        
        expect {
          post :create, params: valid_attributes
        }.not_to change(Tag, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include('Name has already been taken')
      end
    end
  end

  describe 'PUT #update' do
    let(:tag) { create(:tag, name: 'ruby') }

    context 'when user is admin' do
      before do
        request.headers['Authorization'] = "Bearer #{admin_token}"
      end

      it 'updates the tag' do
        put :update, params: { id: tag.id, tag: { name: 'rails' } }
        
        tag.reload
        expect(tag.name).to eq('rails')
        expect(response).to have_http_status(:ok)
      end

      it 'does not update to existing tag name' do
        create(:tag, name: 'rails')
        put :update, params: { id: tag.id, tag: { name: 'rails' } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include('Name has already been taken')
      end
    end

    context 'when user is not admin' do
      before do
        request.headers['Authorization'] = "Bearer #{token}"
      end

      it 'forbids the update' do
        put :update, params: { id: tag.id, tag: { name: 'rails' } }
        
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Only administrators can modify tags')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:tag) { create(:tag) }

    context 'when user is admin' do
      before do
        request.headers['Authorization'] = "Bearer #{admin_token}"
      end

      context 'when tag has no posts' do
        it 'destroys the tag' do
          expect {
            delete :destroy, params: { id: tag.id }
          }.to change(Tag, :count).by(-1)
          
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['message']).to eq('Tag deleted successfully')
        end
      end

      context 'when tag has posts' do
        before { create(:post, tags: [tag]) }

        it 'does not destroy the tag' do
          expect {
            delete :destroy, params: { id: tag.id }
          }.not_to change(Tag, :count)
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq('Cannot delete tag that is still in use')
        end
      end
    end

    context 'when user is not admin' do
      before do
        request.headers['Authorization'] = "Bearer #{token}"
      end

      it 'forbids the deletion' do
        expect {
          delete :destroy, params: { id: tag.id }
        }.not_to change(Tag, :count)
        
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Only administrators can modify tags')
      end
    end
  end
end