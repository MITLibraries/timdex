require 'test_helper'

class OpensearchTest < ActiveSupport::TestCase
  test 'can override index' do
    # fragile test: assumes opensearch instance with at least one index in the `geo` alias
    VCR.use_cassette('opensearch non-default index') do
      params = { title: 'bermuda' }
      results = Opensearch.new.search(0, params, Timdex::OSClient, highlight: false, index: 'geo')
      assert results['hits']['hits'].map { |hit| hit['_index'] }.uniq.map { |index| index.start_with?('gis') }.any?
    end
  end

  test 'default index' do
    # fragile test: assumes opensearch instance with at least one index promoted to timdex-prod and no promoted indexes
    # that start with rdi*
    VCR.use_cassette('opensearch default index') do
      params = { title: 'data' }
      results = Opensearch.new.search(0, params, Timdex::OSClient, highlight: false, index: nil)
      refute results['hits']['hits'].map { |hit| hit['_index'] }.uniq.map { |index| index.start_with?('rdi') }.any?
      assert results['hits']['hits'].map { |hit| hit['_index'] }.uniq.any?
    end
  end

  test 'searches a single field' do
    VCR.use_cassette('opensearch single field') do
      params = { title: 'spice it up' }
      results = Opensearch.new.search(0, params, Timdex::OSClient, highlight: false, index: nil)
      assert_equal 'Spice it up!',
                   results['hits']['hits'].first['_source']['title']
    end
  end

  test 'searches a single field with nested subfields' do
    VCR.use_cassette('opensearch single field nested') do
      params = { contributors: 'mcternan' }
      results = Opensearch.new.search(0, params, Timdex::OSClient, highlight: false, index: nil)
      assert_equal 'A common table : 80 recipes and stories from my shared cultures',
                   results['hits']['hits'].first['_source']['title']
    end
  end

  test 'searches multiple fields' do
    VCR.use_cassette('opensearch multiple fields') do
      params = { q: 'chinese', title: 'common', contributors: 'mcternan' }
      results = Opensearch.new.search(0, params, Timdex::OSClient, highlight: false, index: nil)
      assert_equal 'A common table : 80 recipes and stories from my shared cultures',
                   results['hits']['hits'].first['_source']['title']
    end
  end

  test 'highlights included if requested' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'this' })
    os.instance_variable_set(:@highlight, true)

    assert(os.build_query(0).include?('highlight'))
  end

  test 'highlights not included by default' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'this' })

    refute(os.build_query(0).include?('highlight'))
  end

  test 'build_query uses default size' do
    os = Opensearch.new
    os.instance_variable_set(:@params, {})
    json = JSON.parse(os.build_query(0))
    assert_equal Opensearch::SIZE, json['size']
  end

  test 'build_query respects per_page' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { per_page: 5 })
    json = JSON.parse(os.build_query(0))
    assert_equal 5, json['size']
  end

  test 'build_query falls back for nonpositive per_page' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { per_page: 0 })
    json = JSON.parse(os.build_query(0))
    assert_equal Opensearch::SIZE, json['size']
  end

  test 'build_query caps per_page at MAX_SIZE' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { per_page: Opensearch::MAX_SIZE + 100 })
    json = JSON.parse(os.build_query(0))
    assert_equal Opensearch::MAX_SIZE, json['size']
  end

  test 'can exclude fields from _source' do
    ClimateControl.modify(OPENSEARCH_SOURCE_EXCLUDES: 'field1,field2') do
      os = Opensearch.new
      os.instance_variable_set(:@params, {})
      json = JSON.parse(os.build_query(0))
      assert_equal %w[field1 field2], json['_source']['excludes']
    end
  end

  test 'does not include _source if OPENSEARCH_SOURCE_EXCLUDES is not set' do
    ClimateControl.modify(OPENSEARCH_SOURCE_EXCLUDES: nil) do
      os = Opensearch.new
      os.instance_variable_set(:@params, {})
      json = JSON.parse(os.build_query(0))
      refute json.key?('_source')
    end
  end

  test 'uses LexicalQueryBuilder by default when queryMode is keyword' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'test' })
    os.instance_variable_set(:@fulltext, false)
    os.instance_variable_set(:@query_mode, 'keyword')

    expected_query = { bool: { must: [{ match: { text: { query: 'test' } } }] } }
    mock_builder = mock
    mock_builder.stubs(:build).returns(expected_query)
    LexicalQueryBuilder.expects(:new).once.returns(mock_builder)
    result = os.query

    assert result.is_a?(Hash)
    assert_includes(result.keys, :bool)
  end

  test 'uses SemanticQueryBuilder when queryMode is semantic' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'test' })
    os.instance_variable_set(:@fulltext, false)
    os.instance_variable_set(:@query_mode, 'semantic')

    mock_response = { 'bool' => { 'should' => [{ 'rank_feature' => { 'field' => 'test', 'boost' => 1.0 } }] } }
    mock_builder = mock
    mock_builder.stubs(:build).returns(mock_response)
    SemanticQueryBuilder.expects(:new).once.returns(mock_builder)

    result = os.query
    assert_equal(mock_response, result)
  end

  test 'build_query includes aggregations when requested' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'test' })
    os.instance_variable_set(:@requested_aggregations, %i[source contributors])

    json = JSON.parse(os.build_query(0))
    assert json.key?('aggregations')
    assert json['aggregations'].key?('source')
    assert json['aggregations'].key?('contributors')
    assert_not json['aggregations'].key?('languages')
  end

  test 'build_query excludes aggregations when none requested' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'test' })
    os.instance_variable_set(:@requested_aggregations, [])

    json = JSON.parse(os.build_query(0))
    assert_not json.key?('aggregations')
  end

  test 'build_query excludes aggregations when requested_aggregations is nil' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'test' })
    os.instance_variable_set(:@requested_aggregations, nil)

    json = JSON.parse(os.build_query(0))
    assert_not json.key?('aggregations')
  end

  test 'build_query with aggregations ignores invalid aggregation names' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'test' })
    os.instance_variable_set(:@requested_aggregations, %i[source invalid_agg])

    json = JSON.parse(os.build_query(0))
    assert json.key?('aggregations')
    assert json['aggregations'].key?('source')
    assert_not json['aggregations'].key?('invalid_agg')
  end
end
