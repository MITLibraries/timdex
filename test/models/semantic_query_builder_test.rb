require 'test_helper'

class SemanticQueryBuilderTest < ActiveSupport::TestCase
  setup do
    @builder = SemanticQueryBuilder.new
  end

  def mock_lambda_invoke(query_text, response_data)
    # Use StringIO to simulate real AWS SDK behavior (payload is IO-like, not a plain string)
    mock_response = Struct.new(:payload).new(StringIO.new(response_data.to_json))
    Aws::Lambda::Client.any_instance.expects(:invoke).with do |params|
      # Validate the Lambda is called with correct parameters
      assert_equal ENV.fetch('TIMDEX_SEMANTIC_BUILDER_FUNCTION_NAME', nil), params[:function_name]
      assert_equal 'RequestResponse', params[:invocation_type]
      payload = JSON.parse(params[:payload])
      assert_equal query_text, payload['query']
      true
    end.returns(mock_response)
  end

  test 'returns match_all query when no searchterm provided' do
    params = {}
    result = @builder.build(params)

    assert_equal({ match_all: {} }, result)
  end

  test 'returns match_all query when searchterm is blank' do
    params = { q: '' }
    result = @builder.build(params)

    assert_equal({ match_all: {} }, result)
  end

  test 'returns match_all query when searchterm is only whitespace' do
    params = { q: '   ' }
    result = @builder.build(params)

    assert_equal({ match_all: {} }, result)
  end

  test 'builds semantic query from lambda response' do
    query_text = 'hello world'
    expected_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.hello', 'boost' => 6.94 } },
            { 'rank_feature' => { 'field' => 'embedding_full_record.world', 'boost' => 3.42 } }
          ]
        }
      }
    }

    mock_lambda_invoke(query_text, expected_response)

    params = { q: query_text }
    result = @builder.build(params)

    expected_query = {
      'bool' => {
        'should' => [
          { 'rank_feature' => { 'field' => 'embedding_full_record.hello', 'boost' => 6.94 } },
          { 'rank_feature' => { 'field' => 'embedding_full_record.world', 'boost' => 3.42 } }
        ]
      }
    }

    assert_equal(expected_query, result)
  end

  test 'includes fulltext parameter in call but ignores in implementation' do
    query_text = 'test query'
    expected_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    mock_lambda_invoke(query_text, expected_response)

    params = { q: query_text }
    # fulltext parameter is ignored for semantic queries
    result = @builder.build(params, true)

    expected_query = {
      'bool' => {
        'should' => [
          { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
        ]
      }
    }

    assert_equal(expected_query, result)
  end

  test 'raises error when lambda invocation fails' do
    query_text = 'error test'

    # Create a realistic Lambda error by mocking invoke to raise an error
    Aws::Lambda::Client.any_instance.expects(:invoke).raises(StandardError.new('Lambda service error'))

    params = { q: query_text }

    assert_raises(RuntimeError) do
      @builder.build(params)
    end
  end

  test 'raises error when lambda response is missing query key' do
    query_text = 'no query key'
    invalid_response = { 'result' => {} }

    mock_lambda_invoke(query_text, invalid_response)

    params = { q: query_text }

    assert_raises(RuntimeError) do
      @builder.build(params)
    end
  end

  test 'raises error when lambda response query is not a hash' do
    query_text = 'invalid query type'
    invalid_response = { 'query' => 'not a hash' }

    mock_lambda_invoke(query_text, invalid_response)

    params = { q: query_text }

    assert_raises(RuntimeError) do
      @builder.build(params)
    end
  end

  test 'raises error when lambda response payload is invalid json' do
    query_text = 'invalid json'

    Aws::Lambda::Client.any_instance.expects(:invoke).returns(
      Struct.new(:payload).new(StringIO.new('{ invalid json'))
    )

    params = { q: query_text }

    assert_raises(RuntimeError) do
      @builder.build(params)
    end
  end
end
