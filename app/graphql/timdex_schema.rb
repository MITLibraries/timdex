class TimdexSchema < GraphQL::Schema
  query_analyzer TimdexFieldUsageAnalyzer

  query(Types::QueryType)
end
