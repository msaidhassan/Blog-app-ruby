module Api
  module V1
    class PostsController < ApplicationController
      before_action :set_post, only: [:show, :update, :destroy]
      before_action :authorize_user, only: [:update, :destroy]

      def index
        @posts = Post.includes(:user, :comments, :tags).all
        render json: @posts, include: [:user, :tags, comments: { include: :user }]
      end

      def show
        render json: @post, include: [:user, :tags, comments: { include: :user }]
      end

      def create
        @post = @current_user.posts.build(post_params)
        tag_names = params[:tags]&.split(',')&.map(&:strip) || []
        
        ActiveRecord::Base.transaction do
          # Create or find tags first
          tags = tag_names.map { |name| Tag.find_or_create_by!(name: name.downcase) }
          @post.tags = tags  # Assign tags before saving

          if @post.save
            # Schedule post deletion after 24 hours
            DeleteOldPostsJob.set(wait: 24.seconds).perform_later(@post.id)
            render json: @post, include: [:tags], status: :created
          else
            render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.message }, status: :unprocessable_entity
      end

      def update
        tag_names = params[:tags]&.split(',')&.map(&:strip)
        
        ActiveRecord::Base.transaction do
          if @post.update(post_params)
            if tag_names.present?
              @post.tags.clear
              tag_names.each do |name|
                tag = Tag.find_or_create_by!(name: name.downcase)
                @post.tags << tag
              end
            end
            render json: @post, include: [:tags]
          else
            render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.message }, status: :unprocessable_entity
      end

      def destroy
        @post.destroy
        render json: { message: 'Post deleted successfully' }, status: :ok
      end

      private

      def set_post
        @post = Post.find(params[:id])
      end

      def post_params
        # If params[:post] exists, use it, otherwise use the root params
        parameters = params[:post].present? ? params.require(:post) : params
        parameters.permit(:title, :body)
      end

      def authorize_user
        unless @post.user_id == @current_user.id
          render json: { error: 'Unauthorized to perform this action' }, status: :forbidden
        end
      end
    end
  end
end