module Api
  class TagsController < ApplicationController
    before_action :authenticate_request
    before_action :set_tag, only: [:show, :update, :destroy]
    before_action :check_admin, only: [:create, :update, :destroy]

    def index
      @tags = Tag.includes(posts: :user)
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
      if Tag.where.not(id: @tag.id).exists?(name: tag_params[:name]&.downcase)
        render json: { errors: ['Name has already been taken'] }, status: :unprocessable_entity
        return
      end

      if @tag.update(tag_params)
        render json: @tag
      else
        render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      if @tag.posts.exists?
        render json: { error: 'Cannot delete tag that is still in use' }, status: :unprocessable_entity
        return
      end

      if @tag.destroy
        render json: { message: 'Tag deleted successfully' }, status: :ok
      else
        render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_tag
      @tag = Tag.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Couldn't find Tag" }, status: :not_found
    end

    def tag_params
      params.require(:tag).permit(:name)
    end

    def check_admin
      Rails.logger.debug "Current user admin status: #{@current_user&.admin?}"
      return if @current_user&.admin?
      render json: { error: 'Only administrators can modify tags' }, status: :forbidden
    end
  end
end