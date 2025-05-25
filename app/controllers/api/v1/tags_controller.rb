module Api
  module V1
    class TagsController < ApplicationController
      before_action :set_tag, only: [:show, :update, :destroy]
      before_action :authorize_admin, only: [:update, :destroy]
      
      def index
        @tags = Tag.all
        render json: @tags
      end
      
      def show
        render json: @tag, include: { posts: { include: :user } }
      end
      
      def create
        @tag = Tag.new(tag_params)
        
        if @tag.save
          render json: @tag, status: :created
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def update
        if @tag.update(tag_params)
          render json: @tag
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def destroy
        if @tag.posts.empty?
          @tag.destroy
          render json: { message: 'Tag deleted successfully' }, status: :ok
        else
          render json: { error: 'Cannot delete tag that is still in use' }, status: :unprocessable_entity
        end
      end
      
      private
      
      def set_tag
        @tag = Tag.find(params[:id])
      end
      
      def tag_params
        params.permit(:name)
      end

      def authorize_admin
        unless @current_user.admin?
          render json: { error: 'Only administrators can modify tags' }, status: :forbidden
        end
      end
    end
  end
end