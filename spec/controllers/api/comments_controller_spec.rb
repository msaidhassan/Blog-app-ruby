require 'rails_helper'

RSpec.describe Api::CommentsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post_record) { create(:post, user: user) }
  let(:token) { jwt_encode(user_id: user.id) }
  
  before do
    request.headers['Authorization'] = "Bearer #{token}"
  end

  describe 'GET #index' do
    before { create_list(:comment, 3, post: post_record, user: user) }

    it 'returns all comments for a post' do
      get :index, params: { post_id: post_record.id }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(3)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      { comment: { body: 'Test comment' } }
    end

    context 'with valid parameters' do
      it 'creates a new comment' do
        expect {
          post :create, params: { post_id: post_record.id, **valid_attributes }
        }.to change(Comment, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['body']).to eq('Test comment')
        expect(json_response['user']['id']).to eq(user.id)
      end
    end

    context 'with invalid parameters' do
      it 'does not create comment without body' do
        expect {
          post :create, params: { post_id: post_record.id, comment: { body: '' } }
        }.not_to change(Comment, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 404 for non-existent post' do
        expect {
          post :create, params: { post_id: -1, **valid_attributes }
        }.not_to change(Comment, :count)
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT #update' do
    let!(:comment) { create(:comment, user: user, post: post_record) }
    let(:new_attributes) { { comment: { body: 'Updated comment' } } }

    context 'when user owns the comment' do
      it 'updates the comment' do
        put :update, params: { post_id: post_record.id, id: comment.id, **new_attributes }
        
        comment.reload
        expect(comment.body).to eq('Updated comment')
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user does not own the comment' do
      let!(:other_comment) { create(:comment, user: other_user, post: post_record) }

      it 'does not update the comment' do
        put :update, params: { post_id: post_record.id, id: other_comment.id, **new_attributes }
        
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized to perform this action')
      end
    end

    context 'with invalid parameters' do
      it 'does not update with empty body' do
        put :update, params: { post_id: post_record.id, id: comment.id, comment: { body: '' } }
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user owns the comment' do
      let!(:comment) { create(:comment, user: user, post: post_record) }

      it 'destroys the comment' do
        expect {
          delete :destroy, params: { post_id: post_record.id, id: comment.id }
        }.to change(Comment, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Comment deleted successfully')
      end
    end

    context 'when user does not own the comment' do
      let!(:other_comment) { create(:comment, user: other_user, post: post_record) }

      it 'does not destroy the comment' do
        expect {
          delete :destroy, params: { post_id: post_record.id, id: other_comment.id }
        }.not_to change(Comment, :count)
        
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized to perform this action')
      end
    end

    context 'with non-existent resources' do
      it 'returns 404 for non-existent post' do
        delete :destroy, params: { post_id: -1, id: 1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for non-existent comment' do
        delete :destroy, params: { post_id: post_record.id, id: -1 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end