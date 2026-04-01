require 'aws-sdk-lambda'

class SemanticQueryBuilder
  def build(params, _fulltext = false)
    query_text = params[:q].to_s.strip

    # If no query text provided, return a match_all query (consistent with keyword search behavior)
    return { match_all: {} } if query_text.blank?

    lambda_response = invoke_semantic_builder(query_text)
    parse_lambda_response(lambda_response)
  end

  private

  def invoke_semantic_builder(query_text)
    client_options = {
      region: ENV.fetch('AWS_REGION', 'us-east-1'),
      access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
    }

    client = Aws::Lambda::Client.new(client_options)
    payload = { query: query_text }

    response = client.invoke(
      function_name: ENV.fetch('TIMDEX_SEMANTIC_BUILDER_FUNCTION_NAME', nil),
      invocation_type: 'RequestResponse',
      payload: payload.to_json
    )

    parse_lambda_payload(response.payload)
  rescue StandardError => e
    raise "Semantic query builder Lambda error: #{e.message}"
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
    # We extract and return just the inner query object
    raise "Invalid semantic query builder response: missing 'query' key" unless lambda_response.key?('query')

    query = lambda_response['query']
    raise 'Invalid semantic query builder response: query must be a Hash' unless query.is_a?(Hash)

    query
  end
end
