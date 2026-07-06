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

  # Tests for semantic_options in Lambda payload

  test 'includes semantic options in lambda payload' do
    query_text = 'test query'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    captured_payload = nil
    Aws::Lambda::Client.any_instance.expects(:invoke).with do |args|
      captured_payload = JSON.parse(args[:payload])
      true
    end.returns(Struct.new(:payload).new(StringIO.new(mock_response.to_json)))

    params = { q: query_text }
    semantic_options = { must_boost_threshold: 0.5 }
    @builder.build(params, semantic_options: semantic_options)

    # Verify the payload contains the semantic option
    assert_equal 0.5, captured_payload['must_boost_threshold']
  end

  test 'includes multiple semantic options in lambda payload' do
    query_text = 'test query'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    captured_payload = nil
    Aws::Lambda::Client.any_instance.expects(:invoke).with do |args|
      captured_payload = JSON.parse(args[:payload])
      true
    end.returns(Struct.new(:payload).new(StringIO.new(mock_response.to_json)))

    params = { q: query_text }
    semantic_options = {
      must_boost_threshold: 0.5,
      drop_boost_threshold: 0.2,
      short_query_max_tokens: 10
    }
    @builder.build(params, semantic_options: semantic_options)

    # Verify all semantic options are in the payload
    assert_equal 0.5, captured_payload['must_boost_threshold']
    assert_equal 0.2, captured_payload['drop_boost_threshold']
    assert_equal 10, captured_payload['short_query_max_tokens']
  end

  test 'omits nil semantic options from lambda payload' do
    query_text = 'test query'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    captured_payload = nil
    Aws::Lambda::Client.any_instance.expects(:invoke).with do |args|
      captured_payload = JSON.parse(args[:payload])
      true
    end.returns(Struct.new(:payload).new(StringIO.new(mock_response.to_json)))

    params = { q: query_text }
    semantic_options = {
      must_boost_threshold: 0.5,
      drop_boost_threshold: nil,
      short_query_max_tokens: nil
    }
    @builder.build(params, semantic_options: semantic_options)

    # Verify only non-nil options are in the payload
    assert_equal 0.5, captured_payload['must_boost_threshold']
    # Verify they are not keys in the payload hash
    refute captured_payload.key?('drop_boost_threshold')
    refute captured_payload.key?('short_query_max_tokens')
  end

  test 'omits empty string semantic options from lambda payload' do
    query_text = 'test query'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    captured_payload = nil
    Aws::Lambda::Client.any_instance.expects(:invoke).with do |args|
      captured_payload = JSON.parse(args[:payload])
      true
    end.returns(Struct.new(:payload).new(StringIO.new(mock_response.to_json)))

    params = { q: query_text }
    semantic_options = {
      must_boost_threshold: '',
      drop_boost_threshold: 0.2
    }
    @builder.build(params, semantic_options: semantic_options)

    # Verify empty string options are not included
    refute captured_payload.key?('must_boost_threshold')
    assert_equal 0.2, captured_payload['drop_boost_threshold']
  end

  test 'includes only query key when no semantic options provided' do
    query_text = 'test query'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    captured_payload = nil
    Aws::Lambda::Client.any_instance.expects(:invoke).with do |args|
      captured_payload = JSON.parse(args[:payload])
      true
    end.returns(Struct.new(:payload).new(StringIO.new(mock_response.to_json)))

    params = { q: query_text }
    @builder.build(params, semantic_options: {})

    # Verify only query key is in the payload
    assert_equal({ 'query' => query_text }, captured_payload)
  end

  test 'semantic options payload contains both query and options' do
    query_text = 'test query'
    mock_response = {
      'query' => {
        'bool' => {
          'should' => [
            { 'rank_feature' => { 'field' => 'embedding_full_record.test', 'boost' => 5.0 } }
          ]
        }
      }
    }

    captured_payload = nil
    Aws::Lambda::Client.any_instance.expects(:invoke).with do |args|
      captured_payload = JSON.parse(args[:payload])
      true
    end.returns(Struct.new(:payload).new(StringIO.new(mock_response.to_json)))

    params = { q: query_text }
    semantic_options = {
      must_boost_threshold: 0.75,
      short_query_max_tokens: 5
    }
    @builder.build(params, semantic_options: semantic_options)

    # Verify payload structure contains query and both options
    expected_payload = {
      'query' => query_text,
      'must_boost_threshold' => 0.75,
      'short_query_max_tokens' => 5
    }
    assert_equal expected_payload, captured_payload
  end
end
