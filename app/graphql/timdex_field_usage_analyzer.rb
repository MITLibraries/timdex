# TimdexFieldUsageAnalyzer largely overrides some methods from the inherited FieldUsage
# We to log data in a format we can work with and return it to be used along with Tracers
# to determine which fields are being requested so we can modify our OpenSearch query.
# https://graphql-ruby.org/queries/ast_analysis.html
class TimdexFieldUsageAnalyzer < GraphQL::Analysis::AST::FieldUsage
  # This overrides a GraphQL::Analysis::AST::FieldUsage method
  def result
    Rails.logger.info("GraphQL used fields: #{@used_fields.to_a}")
    Rails.logger.info("GraphQL used deprecated fields: #{@used_deprecated_fields.to_a}")
    Rails.logger.info("GraphQL used deprecated arguments: #{@used_deprecated_arguments.to_a}")
    {
      used_fields: @used_fields.to_a,
      used_deprecated_fields: @used_deprecated_fields.to_a,
      used_deprecated_arguments: @used_deprecated_arguments.to_a
    }
  end
end
