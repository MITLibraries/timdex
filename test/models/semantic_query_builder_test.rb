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

  test 'applies filters to blank query' do
    params = { q: '', source_filter: ['aspace'] }
    result = @builder.build(params)

    # When query is blank but filters are specified, should return bool query with filter clause
    assert result.key?(:bool)
    assert result[:bool].key?(:filter)
    assert result[:bool][:filter].present?
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
      bool: {
        should: [
          { rank_feature: { field: 'embedding_full_record.hello', boost: 6.94 } },
          { rank_feature: { field: 'embedding_full_record.world', boost: 3.42 } }
        ],
        filter: []
      }
    }

    assert_equal(expected_query, result)
  end

  test 'raises error when lambda invocation fails' do
    query_text = 'error test'
    Aws::Lambda::Client.any_instance.expects(:invoke).raises(StandardError.new('Lambda service error'))

    params = { q: query_text }

    assert_raises(SemanticQueryBuilder::LambdaError) do
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

  test 'preserves source_filter in semantic queries' do
    query_text = 'test search'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    setup_mock_lambda(mock_response)

    params = { q: query_text, source_filter: ['aspace'] }
    result = @builder.build(params)

    # Verify filter clause was added to the semantic query
    assert_includes result[:bool].keys, :filter
    assert result[:bool][:filter].present?

    # Verify the filter contains the source filter
    filter_terms = result[:bool][:filter].map { |f| f[:bool][:should].first[:term][:source] }.flatten
    assert_includes filter_terms, 'aspace'
  end

  test 'preserves content_type_filter in semantic queries' do
    query_text = 'test search'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    setup_mock_lambda(mock_response)

    params = { q: query_text, content_type_filter: %w[article book] }
    result = @builder.build(params)

    # Verify filter clause was added to the semantic query
    assert_includes result[:bool].keys, :filter
    assert result[:bool][:filter].present?

    # Verify the filter contains multiple content type filters
    assert_equal 2, result[:bool][:filter].length
  end

  test 'applies empty filters array when no filters specified' do
    query_text = 'test search'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    setup_mock_lambda(mock_response)

    params = { q: query_text }
    result = @builder.build(params)

    # Verify filter clause exists but is empty array
    assert_includes result[:bool].keys, :filter
    assert_equal [], result[:bool][:filter]
  end
end
