require_relative '../../../lib/json_web_token'

module Api
  class AuthenticationController < ApplicationController
    skip_before_action :authenticate_request, only: [:login, :register, :serve_image]
    
    def login
      @user = User.find_by_email(params[:email])
      if @user&.authenticate(params[:password])
        token = JsonWebToken.encode(user_id: @user.id)
        time = Time.now + 24.hours.to_i
        render json: { 
          token: token, 
          exp: time.strftime("%m-%d-%Y %H:%M"),
          user: @user.as_json(except: :password_digest) 
        }, status: :ok
      else
        render json: { error: 'unauthorized' }, status: :unauthorized
      end
    end

    def register
      @user = User.new(user_params.except(:image))
      
      if params[:image].present?
        @user.image.attach(params[:image])
      end
      
      if @user.save
        token = JsonWebToken.encode(user_id: @user.id)
        time = Time.now + 24.hours.to_i
        render json: { 
          token: token, 
          exp: time.strftime("%m-%d-%Y %H:%M"),
          user: @user.as_json(except: :password_digest) 
        }, status: :created
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update_image
      unless params[:image].present?
        render json: { error: 'Image must be add' }, status: :unprocessable_entity
        return
      end

      unless params[:image].content_type.in?(%w[image/jpeg image/png image/gif])
        render json: { error: 'Image must be a JPEG, PNG, or GIF' }, status: :unprocessable_entity
        return
      end

      @current_user.image.attach(params[:image])
      render json: { message: 'Image updated successfully' }
    end

    def serve_image
      user = User.find(params[:id])
      
      if user.image.attached?
        redirect_to rails_blob_url(user.image)
      else
        render json: { error: 'No image attached' }, status: :not_found
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'User not found' }, status: :not_found
    end

    def logout
      render json: { message: 'Successfully logged out' }
    end

    private
    
    def user_params
      params.permit(:name, :email, :password, :image)
    end
  end
end