class TimdexFieldUsageAnalyzer < GraphQL::Analysis::AST::FieldUsage
  # Overriding the inherited FieldUsage result to log data in a format we can work with
  def result
    Rails.logger.info("GraphQL used fields: #{@used_fields.to_a}")
    Rails.logger.info("GraphQL used deprecated fields: #{@used_deprecated_fields.to_a}")
    Rails.logger.info("GraphQL used deprecated arguments: #{@used_deprecated_arguments.to_a}")
  end
end
