require 'rails_helper'

RSpec.describe Api::TagsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe 'GET /tags' do
    it 'returns all tags' do
      request.headers['Authorization'] = "Bearer #{generate_token(user)}"
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /tags/:id' do
    context 'with valid id' do
      let(:tag) { create(:tag) }

      it 'returns the tag' do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :show, params: { id: tag.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid id' do
      it 'returns not found status' do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :show, params: { id: -1 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /tags' do
    context 'when user is admin' do
      it 'creates a new tag' do
        request.headers['Authorization'] = "Bearer #{generate_token(admin)}"
        post :create, params: { tag: { name: 'ruby' } }
        expect(response).to have_http_status(:created)
      end

      it 'returns validation errors for invalid name' do
        request.headers['Authorization'] = "Bearer #{generate_token(admin)}"
        post :create, params: { tag: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when user is not admin' do
      it 'returns forbidden status' do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        post :create, params: { tag: { name: 'ruby' } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /tags/:id' do
    let(:tag) { create(:tag) }

    context 'when user is admin' do
      context 'with valid attributes' do
        it 'updates the tag' do
          request.headers['Authorization'] = "Bearer #{generate_token(admin)}"
          put :update, params: { id: tag.id, tag: { name: 'updated_tag' } }
          expect(response).to have_http_status(:ok)
          expect(tag.reload.name).to eq('updated_tag')
        end
      end

      context 'with duplicate name' do
        it 'returns validation error' do
          create(:tag, name: 'existing_tag')
          request.headers['Authorization'] = "Bearer #{generate_token(admin)}"
          put :update, params: { id: tag.id, tag: { name: 'existing_tag' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when user is not admin' do
      it 'returns forbidden status' do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        put :update, params: { id: tag.id, tag: { name: 'updated_tag' } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /tags/:id' do
    let(:tag) { create(:tag) }

    context 'when user is admin' do
      context 'with unused tag' do
        it 'deletes the tag' do
          request.headers['Authorization'] = "Bearer #{generate_token(admin)}"
          expect {
            delete :destroy, params: { id: tag.id }
          }.to change(Tag, :count).by(-1)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with tag in use' do
        it 'returns unprocessable_entity status' do
          post = create(:post)
          post.tags << tag
          request.headers['Authorization'] = "Bearer #{generate_token(admin)}"
          delete :destroy, params: { id: tag.id }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when user is not admin' do
      it 'returns forbidden status' do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        delete :destroy, params: { id: tag.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end