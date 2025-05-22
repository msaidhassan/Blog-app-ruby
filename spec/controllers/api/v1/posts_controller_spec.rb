require 'rails_helper'

RSpec.describe Api::V1::PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:token) { jwt_encode(user_id: user.id) }
  
  before do
    request.headers['Authorization'] = "Bearer #{token}"
  end

  describe 'GET #index' do
    before { create_list(:post, 3, user: user) }

    it 'returns all posts' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(3)
    end
  end

  describe 'GET #show' do
    let(:post) { create(:post, user: user) }

    it 'returns the post' do
      get :show, params: { id: post.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(post.id)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        post: {
          title: 'Test Post',
          body: 'Test Content'
        },
        tags: 'ruby,rails'
      }
    end

    context 'with valid parameters' do
      it 'creates a new post with tags' do
        expect {
          post :create, params: valid_attributes
        }.to change(Post, :count).by(1)
          .and change(Tag, :count).by(2)
        
        expect(response).to have_http_status(:created)
        created_post = JSON.parse(response.body)
        expect(created_post['tags'].map { |t| t['name'] }).to match_array(['ruby', 'rails'])
      end

      it 'schedules post deletion job' do
        expect {
          post :create, params: valid_attributes
        }.to have_enqueued_job(DeleteOldPostsJob).at(be_within(1.second).of(24.hours.from_now))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a post without title' do
        expect {
          post :create, params: { post: { body: 'Test' }, tags: 'ruby' }
        }.not_to change(Post, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create a post without tags' do
        expect {
          post :create, params: { post: { title: 'Test', body: 'Test' } }
        }.not_to change(Post, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    let!(:post_record) { create(:post, user: user) }
    let(:new_attributes) do
      {
        post: {
          title: 'Updated Title',
          body: 'Updated Content'
        },
        tags: 'updated,tags'
      }
    end

    context 'when user owns the post' do
      it 'updates the post and its tags' do
        put :update, params: new_attributes.merge(id: post_record.id)
        
        post_record.reload
        expect(post_record.title).to eq('Updated Title')
        expect(post_record.tags.pluck(:name)).to match_array(['updated', 'tags'])
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user does not own the post' do
      let!(:other_post) { create(:post, user: other_user) }

      it 'does not update the post' do
        put :update, params: new_attributes.merge(id: other_post.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user owns the post' do
      let!(:post_record) { create(:post, user: user) }

      it 'destroys the post' do
        expect {
          delete :destroy, params: { id: post_record.id }
        }.to change(Post, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when user does not own the post' do
      let!(:other_post) { create(:post, user: other_user) }

      it 'does not destroy the post' do
        expect {
          delete :destroy, params: { id: other_post.id }
        }.not_to change(Post, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end