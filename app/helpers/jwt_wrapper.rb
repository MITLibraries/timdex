module JWTWrapper
  module_function

  def encode(payload, expiration = nil)
    expiration ||= 1

    payload = payload.dup
    payload['exp'] = expiration.to_i.hours.from_now.to_i

    JWT.encode(payload, ENV['JWT_SECRET_KEY'])
  end

  def decode(token)
    JWT.decode(token, ENV['JWT_SECRET_KEY']).first
  end
end
