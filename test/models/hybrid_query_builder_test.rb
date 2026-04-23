require 'test_helper'

class HybridQueryBuilderTest < ActiveSupport::TestCase
  setup do
    @builder = HybridQueryBuilder.new
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

  test 'combines lexical and semantic queries when both succeed' do
    params = { q: 'test query' }

    lexical_result = {
      bool: {
        should: [{ prefix: { title: { value: 'test' } } }],
        must: [{ match: { text: { query: 'test' } } }],
        filter: []
      }
    }

    semantic_result = {
      'bool' => {
        'should' => [
          { 'rank_feature' => { 'field' => 'embedding', 'boost' => 5.0 } }
        ]
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    semantic_mock = mock
    semantic_mock.stubs(:build).returns(semantic_result)
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)
    SemanticQueryBuilder.expects(:new).returns(semantic_mock)

    result = @builder.build(params)

    assert_equal :bool, result.keys.first
    assert_equal :should, result[:bool].keys.first
    assert_equal 2, result[:bool][:should].length
  end

  test 'normalizes string keys to symbols in combined queries' do
    params = { q: 'test' }

    lexical_result = {
      bool: {
        should: [],
        must: [],
        filter: []
      }
    }

    semantic_result = {
      'bool' => {
        'should' => [
          { 'rank_feature' => { 'field' => 'embedding', 'boost' => 5.0 } }
        ]
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    semantic_mock = mock
    semantic_mock.stubs(:build).returns(semantic_result)
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)
    SemanticQueryBuilder.expects(:new).returns(semantic_mock)

    result = @builder.build(params)

    # Verify all keys are symbols in the semantic query after normalization
    semantic_query = result[:bool][:should][0]
    semantic_query.each_key { |k| assert k.is_a?(Symbol), "Expected symbol key, got #{k.inspect}" }
    semantic_query[:bool].each_key { |k| assert k.is_a?(Symbol), "Expected symbol key, got #{k.inspect}" }
  end

  test 'gracefully uses lexical only when semantic builder fails' do
    params = { q: 'test query' }

    lexical_result = {
      bool: {
        should: [{ prefix: { title: { value: 'test' } } }],
        must: [{ match: { text: { query: 'test' } } }],
        filter: []
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    semantic_mock = mock
    semantic_mock.stubs(:build).raises(StandardError.new('Lambda error'))
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)
    SemanticQueryBuilder.expects(:new).returns(semantic_mock)

    result = @builder.build(params)
    assert_equal lexical_result, result
  end
end
