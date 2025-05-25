module JsonWebToken
  def jwt_encode(payload)
    ::JsonWebToken.encode(payload)
  end

  def generate_token(user)
    jwt_encode(user_id: user.id)
  end
end