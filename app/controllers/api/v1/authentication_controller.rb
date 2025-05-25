require_relative '../../../../lib/json_web_token'

module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authenticate_request, only: [:login, :register]
      
      # POST /api/v1/login
      def login
        @user = User.find_by_email(params[:email])
        if @user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: @user.id)
          time = Time.now + 24.hours.to_i
          render json: { token: token, exp: time.strftime("%m-%d-%Y %H:%M"),
                         user: @user.as_json }, status: :ok
        else
          render json: { error: 'unauthorized' }, status: :unauthorized
        end
      end
      
      # POST /api/v1/register
      def register
        @user = User.new(user_params.except(:image))
        
        # Attach image before saving
        if params[:image].present?
          @user.image.attach(params[:image])
        end
        
        if @user.save
          token = JsonWebToken.encode(user_id: @user.id)
          time = Time.now + 24.hours.to_i
          render json: { 
            token: token, 
            exp: time.strftime("%m-%d-%Y %H:%M"),
            user: @user.as_json 
          }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
        
      end

      # POST /api/v1/logout
      def logout
        render json: { message: 'Successfully logged out' }, status: :ok
      end
      
      # PATCH /api/v1/update_image
      def update_image
        if params[:image].blank?
          render json: { error: 'Image must be add' }, status: :unprocessable_entity
          return
        end

        @current_user.image.attach(params[:image])
        if @current_user.valid?
          render json: { message: 'Image updated successfully', user: @current_user }, status: :ok
        else
          render json: { error: @current_user.errors[:image].first }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/:id/image
      def serve_image
        user = User.find(params[:id])
        if user.image.attached?
          redirect_to rails_blob_url(user.image)
        else
          render json: { error: 'No image attached' }, status: :not_found
        end
      end
      
      private
      
      def user_params
        params.permit(:name, :email, :password, :image)
      end
    end
  end
end