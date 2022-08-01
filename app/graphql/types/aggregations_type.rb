module Types
  class AggregationCountType < Types::BaseObject
    field :key, String, null: true
    field :doc_count, Int, null: true
  end

  class AggregationsType < Types::BaseObject
    field :format, [Types::AggregationCountType], null: true
    field :content_type, [Types::AggregationCountType], null: true
    field :contributors, [Types::AggregationCountType], null: true
    field :languages, [Types::AggregationCountType], null: true
    field :literary_form, [Types::AggregationCountType], null: true
    field :source, [Types::AggregationCountType], null: true
    field :subjects, [Types::AggregationCountType], null: true
  end
end
