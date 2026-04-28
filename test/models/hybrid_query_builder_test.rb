require 'test_helper'

class HybridQueryBuilderTest < ActiveSupport::TestCase
  setup do
    @builder = HybridQueryBuilder.new
  end

  test 'returns lexical query when no searchterm provided' do
    params = {}
    lexical_result = {
      bool: {
        should: [],
        must: [],
        filter: [{ term: { content_type: 'article' } }]
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)

    result = @builder.build(params)

    # When q is blank, should return lexical query (preserves filters)
    assert_equal lexical_result, result
  end

  test 'returns lexical query when searchterm is blank' do
    params = { q: '' }
    lexical_result = {
      bool: {
        should: [],
        must: [],
        filter: [{ term: { content_type: 'article' } }]
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)

    result = @builder.build(params)

    assert_equal lexical_result, result
  end

  test 'returns lexical query when searchterm is only whitespace' do
    params = { q: '   ' }
    lexical_result = {
      bool: {
        should: [],
        must: [],
        filter: [{ term: { content_type: 'article' } }]
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)

    result = @builder.build(params)

    assert_equal lexical_result, result
  end

  test 'combines lexical and semantic queries when both succeed' do
    params = { q: 'test query' }

    lexical_result = {
      bool: {
        should: [{ prefix: { title: { value: 'test' } } }],
        must: [{ match: { text: { query: 'test' } } }],
        filter: [{ term: { content_type: 'article' } }]
      }
    }

    semantic_result = {
      bool: {
        should: [
          { rank_feature: { field: 'embedding', boost: 5.0 } }
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

    # Verify hybrid structure contains bool, should, and filter
    assert_includes result, :bool
    assert_includes result[:bool], :should
    assert_includes result[:bool], :filter
    assert_equal 2, result[:bool][:should].length

    # The q multi_match must stays inside the lexical branch (not promoted to top)
    # so semantic-only matches can be returned. Only filters are at top level.
    assert_equal [{ term: { content_type: 'article' } }], result[:bool][:filter]

    # Verify lexical branch contains both should and must (with q multi_match)
    lexical_branch = result[:bool][:should][1]
    assert_includes lexical_branch, :bool
    assert lexical_branch[:bool][:should].present?
    assert_equal [{ match: { text: { query: 'test' } } }], lexical_branch[:bool][:must]
  end

  test 'preserves filters in hybrid queries' do
    params = { q: 'test', content_type_filter: 'article' }

    lexical_result = {
      bool: {
        should: [{ prefix: { title: { value: 'test' } } }],
        must: [],
        filter: [{ term: { content_type: 'article' } }]
      }
    }

    semantic_result = {
      bool: {
        should: [{ rank_feature: { field: 'embedding', boost: 5.0 } }]
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    semantic_mock = mock
    semantic_mock.stubs(:build).returns(semantic_result)
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)
    SemanticQueryBuilder.expects(:new).returns(semantic_mock)

    result = @builder.build(params)

    # Filters from lexical should be applied at top level for both branches
    assert_equal [{ term: { content_type: 'article' } }], result[:bool][:filter]

    # Both semantic and lexical should be in should clause
    assert_equal 2, result[:bool][:should].length
  end

  test 'enforces minimum_should_match when filters are present' do
    params = { q: 'test', content_type_filter: 'article' }

    lexical_result = {
      bool: {
        should: [{ prefix: { title: { value: 'test' } } }],
        must: [],
        filter: [{ term: { content_type: 'article' } }]
      }
    }

    semantic_result = {
      'bool' => {
        'should' => [{ 'rank_feature' => { 'field' => 'embedding', 'boost' => 5.0 } }]
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    semantic_mock = mock
    semantic_mock.stubs(:build).returns(semantic_result)
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)
    SemanticQueryBuilder.expects(:new).returns(semantic_mock)

    result = @builder.build(params)

    # With top-level filters present, require at least one semantic/lexical branch
    # to match so the query does not degrade into a filter-only match
    assert_equal 1, result[:bool][:minimum_should_match]
  end

  test 'omits minimum_should_match when no filters' do
    params = { q: 'test' }

    lexical_result = {
      bool: {
        should: [],
        must: [],
        filter: []
      }
    }

    semantic_result = {
      bool: {
        should: [
          { rank_feature: { field: 'embedding', boost: 5.0 } }
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

    # Without filters, minimum_should_match should not be set
    assert_nil result[:bool][:minimum_should_match]
  end

  test 'semantic matches still respect non-q filters even without matching q' do
    # Verify that non-q filters (title, citation, geo, etc.) are enforced at top level
    # so semantic matches must still satisfy them, while the q multi_match stays in lexical.
    params = { q: 'climate', title: 'arctic' }

    lexical_result = {
      bool: {
        should: [{ prefix: { title: { value: 'climate' } } }],
        must: [{ multi_match: { query: 'climate', fields: %w[title text] } }],
        filter: [{ term: { title: 'arctic' } }]
      }
    }

    semantic_result = {
      bool: {
        should: [{ rank_feature: { field: 'embedding', boost: 5.0 } }]
      }
    }

    lexical_mock = mock
    lexical_mock.stubs(:build).returns(lexical_result)
    semantic_mock = mock
    semantic_mock.stubs(:build).returns(semantic_result)
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)
    SemanticQueryBuilder.expects(:new).returns(semantic_mock)

    result = @builder.build(params)

    # Non-q filters (e.g., title='arctic') are at top level so both semantic and lexical
    # branches must satisfy them. Semantic-only matches matching 'climate' in embeddings
    # can still be returned, as long as they have title='arctic'.
    assert_equal [{ term: { title: 'arctic' } }], result[:bool][:filter]
    assert_equal 2, result[:bool][:should].length

    # The q multi_match stays inside the lexical branch (not at top level),
    # allowing semantic-only matches that don't match the q query but do match filters.
    lexical_branch = result[:bool][:should][1]
    assert_includes lexical_branch[:bool], :must
    assert(lexical_branch[:bool][:must].any? { |c| c.key?(:multi_match) })

    # minimum_should_match enforced since filters present
    assert_equal 1, result[:bool][:minimum_should_match]
  end

  test 'semantic query has symbol keys from semantic builder' do
    params = { q: 'test' }

    lexical_result = {
      bool: {
        should: [],
        must: [],
        filter: []
      }
    }

    # SemanticQueryBuilder now normalizes keys to symbols before returning
    semantic_result = {
      bool: {
        should: [
          { rank_feature: { field: 'embedding', boost: 5.0 } }
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

    # Verify semantic query in should clause has symbol keys (normalized at source)
    semantic_query = result[:bool][:should][0]
    semantic_query.each_key { |k| assert k.is_a?(Symbol), "Expected symbol key, got #{k.inspect}" }
    semantic_query[:bool].each_key { |k| assert k.is_a?(Symbol), "Expected symbol key, got #{k.inspect}" }
  end

  test 'gracefully uses lexical when semantic builder raises LambdaError' do
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
    # SemanticQueryBuilder now raises SemanticQueryBuilder::LambdaError for Lambda failures
    semantic_mock.stubs(:build).raises(SemanticQueryBuilder::LambdaError.new('service unavailable'))
    LexicalQueryBuilder.expects(:new).returns(lexical_mock)
    SemanticQueryBuilder.expects(:new).returns(semantic_mock)

    result = @builder.build(params)

    # When semantic fails with Lambda error, fall back to lexical
    assert_equal lexical_result, result
  end
end
