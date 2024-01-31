module Types
  class AggregationCountType < Types::BaseObject
    field :key, String, null: true, description: 'Aggregation value matched in search'
    field :doc_count, Int, null: true, description: 'Result count for a given aggregation'
  end

  class AggregationsType < Types::BaseObject
    field :format, [Types::AggregationCountType], null: true, description: 'Total search results by format'
    field :content_type, [Types::AggregationCountType], null: true, description: 'Total search results by content type'
    field :contributors, [Types::AggregationCountType], null: true,
                                                        description: 'Total search results by contributor name; e.g., author, editor, etc.'
    field :languages, [Types::AggregationCountType], null: true, description: 'Total search results by language'
    field :literary_form, [Types::AggregationCountType], null: true,
                                                         description: 'Total search results by fiction or nonfiction'
    field :source, [Types::AggregationCountType], null: true,
                                                  description: 'Total search results by source record system'
    field :subjects, [Types::AggregationCountType], null: true, description: 'Total search results by subject term'
    field :year, [Types::AggregationCountType], null: true, description: 'Total search results by year'
  end
end
