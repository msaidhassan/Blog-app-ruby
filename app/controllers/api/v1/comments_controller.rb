module Api
  module V1
    class CommentsController < ApplicationController
      before_action :set_post
      before_action :set_comment, only: [:update, :destroy]
      before_action :authorize_user, only: [:update, :destroy]
      
      def index
        @comments = @post.comments
        render json: @comments
      end
    
      def create
        @comment = @post.comments.build(comment_params)
        @comment.user = @current_user

        if @comment.save
          render json: @comment, include: :user, status: :created
        else
          render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @comment.update(comment_params)
          render json: @comment, include: :user
        else
          render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @comment.destroy
        head :no_content
      end

      private

      def set_post
        @post = Post.find(params[:post_id])
      end

      def set_comment
        @comment = @post.comments.find(params[:id])
      end

      def comment_params
        params.require(:comment).permit(:body)
      end

      def authorize_user
        unless @comment.user_id == @current_user.id
          render json: { error: 'Unauthorized to perform this action' }, status: :forbidden
        end
      end
    end
  end
end