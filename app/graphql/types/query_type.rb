module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :ping, String, null: false, description: 'Is this thing on?'

    def ping
      'Pong!'
    end

    if Flipflop.v2?
      field :record_id, RecordType, null: false,
                                    description: 'Retrieve one timdex record' do
        argument :id, String, required: true
        argument :index, String, required: false, default_value: nil,
                                 description: 'It is not recommended to provide an index value unless we have provided you with one for your specific use case'
      end
    else
      field :record_id, RecordType, null: false,
                                    description: 'Retrieve one timdex record' do
        argument :id, String, required: true
      end
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
      def record_id(id:, index:)
        result = Retrieve.new.fetch(id, Timdex::OSClient, index)
        result['hits']['hits'].first['_source']
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        raise GraphQL::ExecutionError, "Record '#{id}' not found"
      end

      field :search, SearchType, null: false,
                                 description: 'Search for timdex records' do
        argument :searchterm, String, required: false, default_value: nil, description: 'Query all searchable fields'
        argument :citation, String, required: false, default_value: nil, description: 'Search by citation information'
        argument :contributors, String, required: false, default_value: nil,
                                        description: 'Search by contributor name; e.g., author, editor, etc.'
        argument :funding_information, String, required: false, default_value: nil,
                                               description: 'Search by funding information; e.g., funding source, award name, etc.'
        argument :identifiers, String, required: false, default_value: nil,
                                       description: 'Search by unique indentifier; e.g., ISBN, DOI, etc.'
        argument :locations, String, required: false, default_value: nil, description: 'Search by locations'
        argument :subjects, String, required: false, default_value: nil, description: 'Search by subject terms'
        argument :title, String, required: false, default_value: nil, description: 'Search by title'
        argument :from, String, required: false, default_value: '0',
                                description: 'Search result number to begin with (the first result is 0)'
        argument :index, String, required: false, default_value: nil,
                                 description: 'It is not recommended to provide an index value unless we have provided you with one for your specific use case'

        # applied facets
        argument :content_type_facet, [String], required: false, default_value: nil,
                                                description: 'Filter results by content type. Use the `contentType` aggregation for a list of possible values'
        argument :contributors_facet, [String], required: false, default_value: nil,
                                                description: 'Filter results by contributor. Use the `contributors` aggregation for a list of possible values'
        argument :format_facet, [String], required: false, default_value: nil,
                                          description: 'Filter results by format. Use the `format` aggregation for a list of possible values'
        argument :languages_facet, [String], required: false, default_value: nil,
                                             description: 'Filter results by language. Use the `languages` aggregation for a list of possible values'
        argument :literary_form_facet, String, required: false, default_value: nil,
                                               description: 'Filter results by fiction or nonfiction'
        argument :source_facet, [String], required: false, default_value: nil,
                                          description: 'Filter by source record system. Use the `sources` aggregation for a list of possible values'
        argument :subjects_facet, [String], required: false, default_value: nil,
                                            description: 'Filter by subject terms. Use the `contentType` aggregation for a list of possible values'
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
      def search(searchterm:, citation:, contributors:, funding_information:, identifiers:, locations:, subjects:,
                 title:, index:, from:, **facets)
        query = construct_query(searchterm, citation, contributors, funding_information, identifiers, locations,
                                subjects, title, facets)

        results = Opensearch.new.search(from, query, Timdex::OSClient, index)

        response = {}
        response[:hits] = results['hits']['total']['value']
        response[:records] = inject_hits_fields_into_source(results['hits']['hits'])
        response[:aggregations] = collapse_buckets(results['aggregations'])
        response
      end

      # Long-term, we will probably want to define these fields discretely in RecordType. However, this might end up
      # adding confusion while we are maintaining deprecated fields in that class. We should refactor this either soon
      # after removing GraphQL V1 or as part of that work.
      def inject_hits_fields_into_source(hits)
        modded_sources = []
        hits.each do |hit|
          source = hit['_source']
          source['highlight'] = hit['highlight']
          source['score'] = hit['_score']
          modded_sources << source
        end
        modded_sources
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
      def construct_query(searchterm, citation, contributors, funding_information, identifiers, locations, subjects,
                          title, facets)
        query = {}
        query[:q] = searchterm
        query[:citation] = citation
        query[:contributors] = contributors
        query[:funding_information] = funding_information
        query[:identifiers] = identifiers
        query[:locations] = locations
        query[:subjects] = subjects
        query[:title] = title
        query[:collection_facet] = facets[:collection_facet]
        query[:content_format_facet] = facets[:format_facet]
        query[:content_type_facet] = facets[:content_type_facet]
        query[:contributors_facet] = facets[:contributors_facet]
        query[:languages_facet] = facets[:languages_facet]
        query[:literary_form_facet] = facets[:literary_form_facet]
        query[:source_facet] = facets[:source_facet] if facets[:source_facet] != 'All'
        query[:subjects_facet] = facets[:subjects_facet]
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
          format: es_aggs['content_format']['buckets'],
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
