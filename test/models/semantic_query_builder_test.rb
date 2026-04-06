require 'test_helper'

class SemanticQueryBuilderTest < ActiveSupport::TestCase
  setup do
    @builder = SemanticQueryBuilder.new
  end

  # Sets up a mock Lambda response for testing semantic query builder.
  # Mocks Aws::Lambda::Client#invoke to return the provided response_data, simulating AWS SDK
  # payload (StringIO).
  def setup_mock_lambda(response_data)
    mock_response = Struct.new(:payload).new(StringIO.new(response_data.to_json))
    Aws::Lambda::Client.any_instance.expects(:invoke).returns(mock_response)
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
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.hello', 'boost' => 6.94 } },
            { 'rank_feature' => { 'field' => 'embedding_full_record.world', 'boost' => 3.42 } }
          ]
        }
      }
    }

    setup_mock_lambda(mock_response)

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

  test 'raises error when lambda invocation fails' do
    query_text = 'error test'
    Aws::Lambda::Client.any_instance.expects(:invoke).raises(StandardError.new('Lambda service error'))

    params = { q: query_text }

    assert_raises(RuntimeError) do
      @builder.build(params)
    end
  end

  test 'raises error when lambda response is missing query key' do
    query_text = 'no query key'
    invalid_response = { 'result' => {} }

    setup_mock_lambda(invalid_response)

    params = { q: query_text }

    assert_raises(RuntimeError) do
      @builder.build(params)
    end
  end

  test 'raises error when lambda response query is not a hash' do
    query_text = 'invalid query type'
    invalid_response = { 'query' => 'not a hash' }

    setup_mock_lambda(invalid_response)

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
