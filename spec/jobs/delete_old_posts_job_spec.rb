require 'rails_helper'

RSpec.describe DeleteOldPostsJob, type: :job do
  describe '#perform' do
    let!(:recent_post) { create(:post, created_at: 23.hours.ago) }
    let!(:old_post) { create(:post, created_at: 25.hours.ago) }

    context 'when deleting specific post' do
      it 'deletes only the specified old post' do
        expect {
          described_class.perform_now(old_post.id)
        }.to change(Post, :count).by(-1)
        
        expect { old_post.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(recent_post.reload).to be_present
      end

      it 'does not delete recent posts' do
        expect {
          described_class.perform_now(recent_post.id)
        }.not_to change(Post, :count)
        
        expect(recent_post.reload).to be_present
      end
    end

    context 'when performing batch cleanup' do
      it 'deletes all posts older than 24 hours' do
        expect {
          described_class.perform_now
        }.to change(Post, :count).by(-1)
        
        expect { old_post.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(recent_post.reload).to be_present
      end
    end
  end
end