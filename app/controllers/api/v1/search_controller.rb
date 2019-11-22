module Api
  module V1
    class SearchController < ApplicationController
      respond_to :json
      before_action :ensure_json!

      SIZE = 20
      MAX_PAGE = 200

      def search
        page = params[:page].to_i
        page = 1 if page.zero?
        from = page * SIZE - SIZE

        if page > MAX_PAGE
          render json: { error: "Invalid page: max #{MAX_PAGE}" }.to_json,
                 status: :bad_request
        end

        @results = Search.new.search(from, params)
      end

      def record
        @results = Retrieve.new.fetch(params[:id])
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        render json: { error: 'record not found' }.to_json, status: :not_found
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
