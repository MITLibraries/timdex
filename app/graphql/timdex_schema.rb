class TimdexSchema < GraphQL::Schema
  query_analyzer TimdexFieldUsageAnalyzer
  trace_class(GraphQL::Tracing::LegacyTrace)

  query(Types::QueryType)

  use GraphQL::Schema::Visibility

  # Hide arguments marked as "INTERNAL USE ONLY" from introspection queries
  def self.visible?(member, context)
    # 1. Detect if the member is one of your internal arguments
    if member.respond_to?(:description) && member.description&.include?('INTERNAL USE ONLY')

      # 2. Extract the root operation fields being requested
      selected_fields = context.query&.selected_operation&.selections || []

      # 3. Check if any root field starts with "__schema" or "__type"
      is_introspection = selected_fields.any? do |selection|
        selection.respond_to?(:name) && selection.name.start_with?('__')
      end

      # 4. Hide the arguments if GraphiQL/Introspection is sniffing the schema
      return false if is_introspection
    end

    super
  end
end
