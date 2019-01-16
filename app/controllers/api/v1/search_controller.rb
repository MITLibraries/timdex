module Api
  module V1
    class SearchController < ApplicationController
      respond_to :json
      before_action :ensure_json!
      before_action :authenticate_user!, except: 'ping'

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

        @results = Timdex::EsClient.search(index: ENV['ELASTICSEARCH_INDEX'],
                                           body: build_query(from))
      end

      def record
        @results = Timdex::EsClient.get(index: ENV['ELASTICSEARCH_INDEX'],
                                        id: params[:id])
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        render json: { error: 'record not found' }.to_json, status: :not_found
      end

      def ping
        render json: 'pong'.to_json
      end

      def ensure_json!
        request.format = :json
      end

      private

      def build_query(from)
        {
          from: from,
          size: SIZE,
          query: {
            bool: {
              must: {
                multi_match: {
                  query: params[:q]
        # We need to make an array of all of the filters here.
        # The current attempt here was to create an array by looping over a
        # list of all of the parameters that are potential filters.
        # Complicating that is that sometimes we allow multiple values and
        # others just a single value.
                }
              }
            }
          },
          aggregations: {
            creators: {
              terms: {
                field: 'creators.keyword'
              }
            },
            content_type: {
              terms: {
                field: 'content_type.keyword'
              }
            },
            content_format: {
              terms: {
                field: 'format.keyword'
              }
            },
            languages: {
              terms: {
                field: 'languages.keyword'
              }
            },
            literary_form: {
              terms: {
                field: 'literary_form.keyword'
              }
            },
            source: {
              terms: {
                field: 'source.keyword'
              }
            },
            subjects: {
              terms: {
                field: 'subjects.keyword'
              }
            }
          }
        }.to_json
      end
    end
  end
end
