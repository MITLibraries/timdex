module Api
  module V1
    class AuthController < ApplicationController
      respond_to :json
      before_action :ensure_json!
      before_action :authenticate_user!

      def auth
        render json: JwtWrapper.encode(user_id: current_user.id).to_json
      end

      def ensure_json!
        request.format = :json
      end
    end
  end
end
