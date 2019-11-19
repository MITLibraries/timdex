module Types
  class SearchType < Types::BaseObject
    field :records, [Types::RecordType], null: true
    field :aggregations, Types::AggregationsType, null: true
    field :hits, Int, null: false
  end
end
