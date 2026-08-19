class TimdexSchema < GraphQL::Schema
  query_analyzer TimdexFieldUsageAnalyzer
  trace_class(GraphQL::Tracing::LegacyTrace)

  query(Types::QueryType)
end
