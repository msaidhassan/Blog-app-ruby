class DeleteOldPostsJob < ApplicationJob
  include JobProcessor
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(post_id = nil)
    if post_id
      # Delete specific post after 24 hours
      post = Post.find_by(id: post_id)
      post&.destroy if post && post.created_at <= 24.hours.ago
    else
      # Batch cleanup of old posts with logging
      count = 0
      Post.where('created_at <= ?', 24.hours.ago).find_each(batch_size: 100) do |post|
        post.destroy
        count += 1
      end
      Rails.logger.info("DeleteOldPostsJob: Deleted #{count} posts")
    end
  end
end