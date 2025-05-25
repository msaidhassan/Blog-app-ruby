module JsonWebToken
  def jwt_encode(payload)
    ::JsonWebToken.encode(payload)
  end
end