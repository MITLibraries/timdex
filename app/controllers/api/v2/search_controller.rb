module Api
  module V2
    class SearchController < ApplicationController
      respond_to :json
      before_action :ensure_json!

      SIZE = 20
      MAX_PAGE = 200

      def search
        page = params[:page].to_i
        page = 1 if page.zero?
        from = (page * SIZE) - SIZE

        if page > MAX_PAGE
          render json: { error: "Invalid page: max #{MAX_PAGE}" }.to_json,
                 status: :bad_request
        end

        @results = Opensearch.new.search(from, params, Timdex::OSClient)
      end

      def record
        @results = Retrieve.new.fetch(params[:id], Timdex::OSClient)
      rescue OpenSearch::Transport::Transport::Errors::NotFound
        render json: { error: 'record not found' }.to_json, status: :not_found
      end

      def ping
        render json: 'pong'.to_json
      end

      def info
        @results = Timdex::OSClient.info
      end

      def ensure_json!
        request.format = :json
      end
    end
  end
end
