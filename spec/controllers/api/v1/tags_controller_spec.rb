require 'rails_helper'

RSpec.describe Api::V1::TagsController, type: :controller do
  let(:user) { create(:user) }
  let(:token) { jwt_encode(user_id: user.id) }

  before do
    request.headers['Authorization'] = "Bearer #{token}"
  end

  describe 'GET #index' do
    before { create_list(:tag, 3) }

    it 'returns all tags' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(3)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) { { name: 'ruby' } }
    let(:invalid_attributes) { { name: '' } }

    context 'with valid parameters' do
      it 'creates a new tag' do
        expect {
          post :create, params: { tag: valid_attributes }
        }.to change(Tag, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a tag' do
        expect {
          post :create, params: { tag: invalid_attributes }
        }.not_to change(Tag, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    let!(:tag) { create(:tag) }
    let(:new_attributes) { { name: 'rails' } }

    context 'with valid parameters' do
      it 'updates the tag' do
        put :update, params: { id: tag.id, tag: new_attributes }
        tag.reload
        expect(tag.name).to eq('rails')
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'does not update the tag' do
        put :update, params: { id: tag.id, tag: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when tag has no posts' do
      let!(:tag) { create(:tag) }

      it 'destroys the tag' do
        expect {
          delete :destroy, params: { id: tag.id }
        }.to change(Tag, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when tag has posts' do
      let!(:tag) { create(:tag) }
      let!(:post) { create(:post) }

      before do
        post.tags << tag
      end

      it 'does not destroy the tag' do
        expect {
          delete :destroy, params: { id: tag.id }
        }.not_to change(Tag, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end