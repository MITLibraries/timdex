class AuthController < ApplicationController
  respond_to :json
  before_action :ensure_json!
  before_action :authenticate_user!

  def auth
    render json: JWTWrapper.encode(user_id: current_user.id)
  end

  def ensure_json!
    request.format = :json
  end
end
