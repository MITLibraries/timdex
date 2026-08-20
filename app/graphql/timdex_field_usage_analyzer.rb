# TimdexFieldUsageAnalyzer overrides FieldUsage so we can collect query usage data
# (including deprecated fields and arguments) and place it directly on GraphQL context.
# Resolvers then read this context data to shape OpenSearch query behavior and logging.
# https://graphql-ruby.org/queries/ast_analysis.html
class TimdexFieldUsageAnalyzer < GraphQL::Analysis::AST::FieldUsage
  # This overrides a GraphQL::Analysis::AST::FieldUsage method
  def result
    analysis_data = {
      used_fields: @used_fields.to_a,
      used_deprecated_fields: @used_deprecated_fields.to_a,
      used_deprecated_arguments: @used_deprecated_arguments.to_a
    }

    query.context[:graphql_analysis] = analysis_data
    analysis_data
  end
end
