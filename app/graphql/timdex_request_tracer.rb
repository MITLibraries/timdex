# TimdexRequestTracer will populate the context of a query with data from our analyzers so we
# can use the data to modify how we contstruct queries
# It is called from the graphql_controller as part of the request context.
# https://graphql-ruby.org/queries/executing_queries.html#context
# https://graphql-ruby.org/queries/tracing.html
# https://medium.com/omada-health-tech/graphql-tips-the-backend-553375e1b669
class TimdexRequestTracer
  attr_accessor :log_data

  def trace(key, _data)
    result = yield
    self.log_data = result.first if key == 'analyze_query'
    result
  end
end
