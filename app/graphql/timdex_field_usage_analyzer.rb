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

    if Flipflop.enabled?(:prometheus)
      # Increment deprecated field usage counter per field
      @used_deprecated_fields.each do |field|
        Timdex::GraphqlDeprecatedFieldUsage.increment(labels: { field: })
      end

      # Increment field usage counter per field
      @used_fields.each do |field|
        next if @used_deprecated_fields.include?(field)
        next if field.start_with?('_')

        Timdex::GraphqlFieldUsage.increment(labels: { field: })
      end

      # Increment deprecated argument counter per argument
      @used_deprecated_arguments.each do |field|
        Timdex::GraphqlDeprecatedArguments.increment(labels: { field: })
      end
    end

    {
      used_fields: @used_fields.to_a,
      used_deprecated_fields: @used_deprecated_fields.to_a,
      used_deprecated_arguments: @used_deprecated_arguments.to_a
    }
  end
end
