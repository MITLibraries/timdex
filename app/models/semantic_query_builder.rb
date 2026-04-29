class SemanticQueryBuilder
  # Dedicated exception for Lambda invocation failures (not parsing/validation errors)
  class LambdaError < StandardError; end

  def build(params, fulltext: false)
    query_text = params[:q].to_s.strip

    # If no query text provided, return a match_all query (consistent with keyword search behavior)
    return { match_all: {} } if query_text.blank?

    lambda_response = invoke_semantic_builder(query_text)
    parse_lambda_response(lambda_response)
  end

  private

  def invoke_semantic_builder(query_text)
    payload = { query: query_text }
    function_name = ENV.fetch('TIMDEX_SEMANTIC_BUILDER_FUNCTION_NAME')

    begin
      response = Timdex::LambdaClient.invoke(
        function_name: function_name,
        invocation_type: 'RequestResponse',
        payload: payload.to_json
      )
    rescue StandardError => e
      # All errors from the Lambda service call are wrapped in LambdaError
      # so HybridQueryBuilder can catch it and gracefully fall back to lexical search.
      raise LambdaError, "Lambda invocation error: #{e.message}", e.backtrace
    end

    # Response parsing below is outside the rescue block, so JSON/validation errors
    # propagate as-is and fail fast rather than triggering graceful fallback.
    parse_lambda_payload(response.payload)
  end

  def parse_lambda_payload(payload)
    # AWS Lambda response payload can be an IO-like object (e.g., StringIO) or a string
    payload_str = if payload.respond_to?(:read)
                    payload.read
                  else
                    payload.to_s
                  end
    JSON.parse(payload_str)
  rescue JSON::ParserError => e
    raise "Invalid JSON response from semantic query builder: #{e.message}"
  end

  def parse_lambda_response(lambda_response)
    # Lambda returns: { "query": { "bool": { "should": [...] } } }
    # We extract and return just the inner query object with keys normalized to symbols
    raise "Invalid semantic query builder response: missing 'query' key" unless lambda_response.key?('query')

    query = lambda_response['query']
    raise 'Invalid semantic query builder response: query must be a Hash' unless query.is_a?(Hash)

    # Normalize string keys to symbols for consistency with LexicalQueryBuilder
    normalize_keys(query)
  end

  # Recursively converts all string keys to symbols in hashes and nested structures.
  def normalize_keys(value)
    case value
    when Hash
      value.transform_keys { |k| k.is_a?(String) ? k.to_sym : k }
           .transform_values { |v| normalize_keys(v) }
    when Array
      value.map { |item| normalize_keys(item) }
    else
      value
    end
  end
end
