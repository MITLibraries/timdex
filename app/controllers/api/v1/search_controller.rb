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
          query: query,
          aggregations: aggregations
        }.to_json
      end

      def query
        {
          bool: {
            must: {
              multi_match: {
                query: params[:q]
              }
            },
            filter: filters
          }
        }
      end

      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
      def filters
        f = []
        if params[:contributors]
          f.push filter(params[:contributors], 'contributors')
        end

        if params[:content_type]
          f.push filter_single(params[:content_type], 'content_type')
        end

        if params[:content_format]
          f.push filter(params[:content_format], 'format')
        end

        f.push filter(params[:language], 'languages') if params[:language]

        if params[:literary_form]
          f.push filter_single(params[:literary_form], 'literary_form')
        end

        f.push filter_single(params[:source], 'source') if params[:source]
        f.push filter(params[:subject], 'subjects') if params[:subject]
        f
      end

      # use `filter` when we accept multiple of the same parameter in our data
      # model
      def filter(param, field)
        terms = []

        param.each do |t|
          if field == 'contributors'
            terms.push(
              {
                nested: {
                  path: "contributors",
                  query: {
                    bool: {
                      must: [{
                        match: {
                          "contributors.value.keyword": t
                        }
                      }]
                    }
                  }
                }
              }
            )
          else
            terms.push('term': { "#{field}.keyword": t })
          end
        end

        terms
      end

      # use `filter_single` when we only accept a single value in our data model
      def filter_single(param, field)
        {
          'term': { "#{field}.keyword": param }
        }
      end

      # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html
      def aggregations
        {
          contributors: {
            nested: {
              path: 'contributors'
            },
            aggs: {
              contributor_names: {
                terms: {
                  field: 'contributors.value.keyword'
                }
              }
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
      end
    end
  end
end
