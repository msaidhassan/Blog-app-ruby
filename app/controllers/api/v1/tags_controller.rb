module Api
  module V1
    class TagsController < ApplicationController
      before_action :set_tag, only: [:show, :update, :destroy]
      
      def index
        @tags = Tag.all
        render json: @tags
      end
      
      def show
        render json: @tag
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
          head :no_content
        else
          render json: { error: 'Cannot delete tag that is still in use' }, status: :unprocessable_entity
        end
      end
      
      private
      
      def set_tag
        @tag = Tag.find(params[:id])
      end
      
      def tag_params
        params.require(:tag).permit(:name)
      end
    end
  end
end