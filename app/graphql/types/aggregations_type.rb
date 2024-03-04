module Types
  class AggregationCountType < Types::BaseObject
    field :key, String, null: true, description: 'Aggregation value matched in search'
    field :doc_count, Int, null: true, description: 'Result count for a given aggregation'
  end

  class AggregationsType < Types::BaseObject
    field :access_to_files, [Types::AggregationCountType],
          null: true,
          description: 'Total seach results by access type (which is a Right with description `Access to files`). ' \
                       'This is only applicable to geospatial records at this time.'
    field :format, [Types::AggregationCountType], null: true, description: 'Total search results by format'
    field :content_type, [Types::AggregationCountType], null: true, description: 'Total search results by content type'
    field :contributors, [Types::AggregationCountType], null: true,
                                                        description: 'Total search results by contributor name; ' \
                                                                     'e.g., author, editor, etc.'
    field :languages, [Types::AggregationCountType], null: true, description: 'Total search results by language'
    field :literary_form, [Types::AggregationCountType], null: true,
                                                         description: 'Total search results by fiction or nonfiction'
    field :source, [Types::AggregationCountType], null: true,
                                                  description: 'Total search results by source record system'
    field :subjects, [Types::AggregationCountType], null: true, description: 'Total search results by subject term'
    field :places, [Types::AggregationCountType], null: true,
                                                  description: 'Total search results by Place (which is a subject ' \
                                                               'with type `Dublin Core; Spatial`)'
  end
end
