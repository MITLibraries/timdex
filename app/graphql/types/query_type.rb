# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
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
      argument :index, String, required: false, default_value: nil,
                               description: 'It is not recommended to provide an index value unless we have provided ' \
                                            'you with one for your specific use case'
    end

    field :info, InfoType, null: false, description: 'Information about the current endpoint'

    def info
      i = Timdex::OSClient.info
      Rails.logger.info(i)
      i
    end

    def record_id(id:, index:)
      result = Retrieve.new.fetch(id, Timdex::OSClient, index)
      result['hits']['hits'].first['_source']
    rescue OpenSearch::Transport::Transport::Errors::NotFound
      raise GraphQL::ExecutionError, "Record '#{id}' not found"
    end

    field :search, SearchType, null: false,
                               description: 'Search for timdex records' do
      argument :searchterm, String, required: false, default_value: nil, description: 'Query all searchable fields'
      argument :citation, String, required: false, default_value: nil, description: 'Search by citation information'
      argument :contributors, String, required: false, default_value: nil,
                                      description: 'Search by contributor name; e.g., author, editor, etc.'
      argument :funding_information, String, required: false, default_value: nil,
                                             description: 'Search by funding information; e.g., funding source, ' \
                                                          'award name, etc.'
      argument :geodistance, GeodistanceType, required: false, default_value: nil,
                                              description: 'Search within a certain distance of a specific location'
      argument :geobox, GeoboxType, required: false, default_value: nil,
                                    description: 'Search within a specified box'
      argument :identifiers, String, required: false, default_value: nil,
                                     description: 'Search by unique indentifier; e.g., ISBN, DOI, etc.'
      argument :locations, String, required: false, default_value: nil, description: 'Search by locations'
      argument :subjects, String, required: false, default_value: nil, description: 'Search by subject terms'
      argument :title, String, required: false, default_value: nil, description: 'Search by title'
      argument :from, String, required: false, default_value: '0',
                              description: 'Search result number to begin with (the first result is 0)'
      argument :index, String, required: false, default_value: nil,
                               description: 'It is not recommended to provide an index value unless we have provided ' \
                                            'you with one for your specific use case'

      argument :source, String, required: false, default_value: 'All', deprecation_reason: 'Use `sourceFilter`'

      # applied filters
      argument :content_type_filter, [String], required: false, default_value: nil,
                                               description: 'Filter results by content type. Use the `contentType` ' \
                                                            'aggregation for a list of possible values. Multiple ' \
                                                            'values are ANDed.'
      argument :contributors_filter, [String], required: false, default_value: nil,
                                               description: 'Filter results by contributor. Use the `contributors` ' \
                                                            'aggregation for a list of possible values. Multiple ' \
                                                            'values are ANDed.'
      argument :format_filter, [String], required: false, default_value: nil,
                                         description: 'Filter results by format. Use the `format` aggregation for a ' \
                                                      'list of possible values. Multiple values are ANDed.'
      argument :languages_filter, [String], required: false, default_value: nil,
                                            description: 'Filter results by language. Use the `languages` ' \
                                                         'aggregation for a list of possible values. Multiple values ' \
                                                         'are ANDed.'
      argument :literary_form_filter, String, required: false, default_value: nil,
                                              description: 'Filter results by fiction or nonfiction'
      argument :places_filter, [String], required: false, default_value: nil,
                                         description: 'Filter by places. Use the `places` aggregation ' \
                                                      'for a list of possible values. Multiple values are ANDed.'
      argument :source_filter, [String], required: false, default_value: nil,
                                         description: 'Filter by source record system. Use the `sources` aggregation ' \
                                                      'for a list of possible values. Multiple values are ORed.'
      argument :subjects_filter, [String], required: false, default_value: nil,
                                           description: 'Filter by subject terms. Use the `contentType` aggregation ' \
                                                        'for a list of possible values. Multiple values are ANDed.'
    end

    def search(searchterm:, citation:, contributors:, funding_information:, geodistance:, geobox:, identifiers:,
               locations:, subjects:, title:, index:, source:, from:, **filters)
      query = construct_query(searchterm, citation, contributors, funding_information, geodistance, geobox, identifiers,
                              locations, subjects, title, source, filters)

      results = Opensearch.new.search(from, query, Timdex::OSClient, highlight_requested?, index)

      response = {}
      response[:hits] = results['hits']['total']['value']
      response[:records] = inject_hits_fields_into_source(results['hits']['hits'])
      response[:aggregations] = collapse_buckets(results['aggregations'])
      response
    end

    def highlight_requested?
      context[:tracers].first.log_data[:used_fields].include?('Record.highlight')
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

    def construct_query(searchterm, citation, contributors, funding_information, geodistance, geobox, identifiers,
                        locations, subjects, title, source, filters)
      query = {}
      query[:q] = searchterm
      query[:citation] = citation
      query[:contributors] = contributors
      query[:funding_information] = funding_information
      query[:geodistance] = geodistance
      query[:geobox] = geobox
      query[:identifiers] = identifiers
      query[:locations] = locations
      query[:subjects] = subjects
      query[:title] = title
      query[:collection_filter] = filters[:collection_filter]
      query[:content_format_filter] = filters[:format_filter]
      query[:content_type_filter] = filters[:content_type_filter]
      query[:contributors_filter] = filters[:contributors_filter]
      query[:languages_filter] = filters[:languages_filter]
      query[:literary_form_filter] = filters[:literary_form_filter]
      query[:places_filter] = filters[:places_filter]
      query = source_deprecation_handler(query, filters[:source_filter], source)
      query[:subjects_filter] = filters[:subjects_filter]
      query
    end

    # source_deprecation_handler prefers our new `sourceFilter` array but will fall back on the
    # depreacted `source` String if it is present and the new version is not
    def source_deprecation_handler(query, new_source, old_source)
      query[:source_filter] = [old_source] if old_source != 'All' && old_source.present?
      query[:source_filter] = new_source if new_source != 'All' && new_source.present?
      query
    end

    def collapse_buckets(es_aggs)
      {
        access_to_files: es_aggs['access_to_files']['only_file_access']['access_types']['buckets'],
        contributors: es_aggs['contributors']['contributor_names']['buckets'],
        source: es_aggs['source']['buckets'],
        subjects: es_aggs['subjects']['subject_names']['buckets'],
        places: es_aggs['places']['only_spatial']['place_names']['buckets'],
        languages: es_aggs['languages']['buckets'],
        literary_form: es_aggs['literary_form']['buckets'],
        format: es_aggs['content_format']['buckets'],
        content_type: es_aggs['content_type']['buckets']
      }
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/MethodLength
