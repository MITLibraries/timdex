module Api
  module V1
    class SearchController < ApplicationController
      respond_to :json
      before_action :ensure_json!
      before_action :authenticate_user!, except: 'ping'

      def search
        @results = Timdex::EsClient.search(q: params[:q])
      end

      def record
        @results = Timdex::EsClient.get(index: 'timdex', id: params[:id])
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        render json: 'record not found', status: :not_found
      end

      def ping
        render json: 'pong'.to_json
      end

      def ensure_json!
        request.format = :json
      end
    end
  end
end
