require_relative 'json_web_token'

class AdminConstraint
  def matches?(request)
    return false unless request.headers['Authorization'].present?

    token = request.headers['Authorization'].split(' ').last
    decoded = JsonWebToken.decode(token)
    
    if decoded
      user = User.find(decoded[:user_id])
      user&.admin?
    end
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    false
  end
end