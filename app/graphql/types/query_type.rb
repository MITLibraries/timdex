module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :ping, String, null: false, description: 'Is this thing on?'

    def ping
      'Pong!'
    end

    field :record_id, RecordType, null: false,
                                  description: 'Retrieve one timdex record' do
      argument :id, String, required: true
    end

    if Flipflop.v2?

      field :info, InfoType, null: false, description: 'Information about the current endpoint'

      def info
        i = Timdex::OSClient.info
        Rails.logger.info(i)
        i
      end
    end

    if Flipflop.v2?
      def record_id(id:)
        result = Retrieve.new.fetch(id, Timdex::OSClient)
        result['hits']['hits'].first['_source']
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        raise GraphQL::ExecutionError, "Record '#{id}' not found"
      end

      field :search, SearchType, null: false,
                                 description: 'Search for timdex records' do
        argument :searchterm, String, required: false, default_value: nil
        argument :title, String, required: false, default_value: nil
        argument :from, String, required: false, default_value: '0'

        # applied facets
        argument :content_type, String, required: false, default_value: nil
        argument :contributors, [String], required: false, default_value: nil
        argument :format, [String], required: false, default_value: nil
        argument :languages, [String], required: false, default_value: nil
        argument :literary_form, String, required: false, default_value: nil
        argument :source, String, required: false, default_value: 'All'
        argument :subjects, [String], required: false, default_value: nil
      end
    else
      def record_id(id:)
        result = Retrieve.new.fetch(id, Timdex::EsClient)
        result['hits']['hits'].first['_source']
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        raise GraphQL::ExecutionError, "Record '#{id}' not found"
      end

      field :search, SearchType, null: false,
                                 description: 'Search for timdex records' do
        argument :searchterm, String, required: true
        argument :from, String, required: false, default_value: '0'

        # applied facets
        argument :content_type, String, required: false, default_value: nil
        argument :contributors, [String], required: false, default_value: nil
        argument :format, [String], required: false, default_value: nil
        argument :languages, [String], required: false, default_value: nil
        argument :literary_form, String, required: false, default_value: nil
        argument :source, String, required: false, default_value: 'All'
        argument :subjects, [String], required: false, default_value: nil
      end
    end

    if Flipflop.v2?
      def search(searchterm:, title:, from:, **facets)
        query = construct_query(searchterm, title, facets)

        results = Opensearch.new.search(from, query, Timdex::OSClient)

        response = {}
        response[:hits] = results['hits']['total']['value']
        response[:records] = results['hits']['hits'].map { |x| x['_source'] }
        response[:aggregations] = collapse_buckets(results['aggregations'])
        response
      end
    else
      def search(searchterm:, from:, **facets)
        query = construct_query(searchterm, facets)

        results = Search.new.search(from, query, Timdex::EsClient)

        response = {}
        response[:hits] = results['hits']['total']
        response[:records] = results['hits']['hits'].map { |x| x['_source'] }
        response[:aggregations] = collapse_buckets(results['aggregations'])
        response
      end
    end

    if Flipflop.v2?
      def construct_query(searchterm, title, facets)
        query = {}
        query[:q] = searchterm
        query[:title] = title
        query[:content_format] = facets[:format]
        query[:content_type] = facets[:content_type]
        query[:contributor] = facets[:contributors]
        query[:language] = facets[:languages]
        query[:literary_form] = facets[:literary_form]
        query[:source] = facets[:source] if facets[:source] != 'All'
        query[:subject] = facets[:subjects]
        query
      end
    else
      def construct_query(searchterm, facets)
        query = {}
        query[:q] = searchterm
        query[:content_format] = facets[:format]
        query[:content_type] = facets[:content_type]
        query[:contributor] = facets[:contributors]
        query[:language] = facets[:languages]
        query[:literary_form] = facets[:literary_form]
        query[:source] = facets[:source] if facets[:source] != 'All'
        query[:subject] = facets[:subjects]
        query
      end
    end

    if Flipflop.v2?
      def collapse_buckets(es_aggs)
        {
          contributors: es_aggs['contributors']['contributor_names']['buckets'],
          source: es_aggs['source']['buckets'],
          subjects: es_aggs['subjects']['subject_names']['buckets'],
          languages: es_aggs['languages']['buckets'],
          literary_form: es_aggs['literary_form']['buckets'],

          content_format: es_aggs['content_format']['buckets'],
          content_type: es_aggs['content_type']['buckets']

        }
      end
    else
      def collapse_buckets(es_aggs)
        {
          content_format: es_aggs['content_format']['buckets'],
          content_type: es_aggs['content_type']['buckets'],
          contributors: es_aggs['contributors']['contributor_names']['buckets'],
          languages: es_aggs['languages']['buckets'],
          literary_form: es_aggs['literary_form']['buckets'],
          source: es_aggs['source']['buckets'],
          subjects: es_aggs['subjects']['buckets']
        }
      end
    end
  end
end
