require 'test_helper'

class OpensearchTest < ActiveSupport::TestCase
  test 'matches citation' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { citation: 'foo' })

    assert(os.matches.to_json.include?('{"match":{"citation":"foo"}}'))
  end

  test 'matches title' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { title: 'foo' })

    assert(os.matches.to_json.include?('{"match":{"title":"foo"}}'))
  end

  test 'matches contributors' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { contributors: 'foo' })

    assert(os.matches.to_json.include?('{"match":{"contributors.value":"foo"}}'))
  end

  test 'matches funding_information' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { funding_information: 'foo' })

    assert(os.matches.to_json.include?('{"match":{"funding_information.funder_name":"foo"}}'))
  end

  test 'matches identifiers' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { identifiers: 'foo' })

    assert(os.matches.to_json.include?('{"match":{"identifiers.value":"foo"}}'))
  end

  test 'matches locations' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { locations: 'foo' })

    assert(os.matches.to_json.include?('{"match":{"locations.value":"foo"}}'))
  end

  test 'matches subjects' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { subjects: 'foo' })

    assert(os.matches.to_json.include?('{"match":{"subjects.value":"foo"}}'))
  end

  test 'matches everything' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'this', citation: 'here', title: 'is', contributors: 'a',
                                         funding_information: 'real', identifiers: 'search', locations: 'rest',
                                         subjects: 'assured,' })

    assert(os.matches.to_json.include?('{"multi_match":{"query":"this","fields":'))
    assert(os.matches.to_json.include?('{"match":{"citation":"here"}}'))
    assert(os.matches.to_json.include?('{"match":{"title":"is"}}'))
    assert(os.matches.to_json.include?('{"match":{"contributors.value":"a"}}'))
    assert(os.matches.to_json.include?('{"match":{"funding_information.funder_name":"real"}}'))
    assert(os.matches.to_json.include?('{"match":{"identifiers.value":"search"}}'))
    assert(os.matches.to_json.include?('{"match":{"locations.value":"rest"}}'))
    assert(os.matches.to_json.include?('{"match":{"subjects.value":"assured,"}}'))
  end

  test 'can override index' do
    # fragile test: assumes opensearch instance with at least one index in the `geo` alias
    VCR.use_cassette('opensearch non-default index') do
      params = { title: 'bermuda' }
      results = Opensearch.new.search(0, params, Timdex::OSClient, false, 'geo')
      assert results['hits']['hits'].map { |hit| hit['_index'] }.uniq.map { |index| index.start_with?('gis') }.any?
    end
  end

  test 'default index' do
    # fragile test: assumes opensearch instance with at least one index promoted to timdex-prod and no promoted indexes
    # that start with rdi*
    VCR.use_cassette('opensearch default index') do
      params = { title: 'data' }
      results = Opensearch.new.search(0, params, Timdex::OSClient)
      refute results['hits']['hits'].map { |hit| hit['_index'] }.uniq.map { |index| index.start_with?('rdi') }.any?
      assert results['hits']['hits'].map { |hit| hit['_index'] }.uniq.any?
    end
  end

  test 'fulltext is included when requested' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'this' })
    os.instance_variable_set(:@fulltext, true)

    assert(os.matches.to_json.include?('"fields":["alternate_titles","call_numbers","citation","contents","contributors.value","dates.value","edition","funding_information.*","identifiers.value","languages","locations.value","notes.value","numbering","publication_information","subjects.value","summary","title","fulltext"]'))
  end

  test 'fulltext is not included by default' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'this' })

    assert(os.matches.to_json.include?('"fields":["alternate_titles","call_numbers","citation","contents","contributors.value","dates.value","edition","funding_information.*","identifiers.value","languages","locations.value","notes.value","numbering","publication_information","subjects.value","summary","title"]'))
  end

  test 'searches a single field' do
    VCR.use_cassette('opensearch single field') do
      params = { title: 'spice it up' }
      results = Opensearch.new.search(0, params, Timdex::OSClient)
      assert_equal 'Spice it up!',
                   results['hits']['hits'].first['_source']['title']
    end
  end

  test 'searches a single field with nested subfields' do
    VCR.use_cassette('opensearch single field nested') do
      params = { contributors: 'mcternan' }
      results = Opensearch.new.search(0, params, Timdex::OSClient)
      assert_equal 'A common table : 80 recipes and stories from my shared cultures',
                   results['hits']['hits'].first['_source']['title']
    end
  end

  test 'searches multiple fields' do
    VCR.use_cassette('opensearch multiple fields') do
      params = { q: 'chinese', title: 'common', contributors: 'mcternan' }
      results = Opensearch.new.search(0, params, Timdex::OSClient)
      assert_equal 'A common table : 80 recipes and stories from my shared cultures',
                   results['hits']['hits'].first['_source']['title']
    end
  end

  test 'source_array creates correct query structure' do
    sources = ['Zenodo', 'DSpace@MIT']
    expected = [{ term: { source: 'Zenodo' } }, { term: { source: 'DSpace@MIT' } }]

    assert_equal(expected, Opensearch.new.source_array(sources))
  end

  test 'filter_sources creates correct query structure' do
    sources = ['Zenodo', 'DSpace@MIT']
    expected = { bool: { should: [{ term: { source: 'Zenodo' } },
                                  { term: { source: 'DSpace@MIT' } }] } }

    assert_equal(expected, Opensearch.new.filter_sources(sources))
  end

  test 'access_to_files_array creates correct query structure' do
    rights = ['MIT authentication', 'Free/open to all']
    expected = [{ term: { 'rights.description.keyword': 'MIT authentication' } },
                { term: { 'rights.description.keyword': 'Free/open to all' } }]

    assert_equal(expected, Opensearch.new.access_to_files_array(rights))
  end

  test 'filter_access_to_files creates correct query structure' do
    sources = ['MIT authentication', 'Free/open to all']
    expected = { nested: { path: 'rights',
                           query: { bool: { should: [
                             { term: { 'rights.description.keyword': 'MIT authentication' } },
                             { term: { 'rights.description.keyword': 'Free/open to all' } }
                           ] } } } }

    assert_equal(expected, Opensearch.new.filter_access_to_files(sources))
  end

  test 'filter_field_by_value query structure' do
    expected = {
      term: { fakefield: 'i am a fake value' }
    }

    assert_equal(expected, Opensearch.new.filter_field_by_value('fakefield', 'i am a fake value'))
  end

  test 'filters query structure when no filters passed' do
    expected_filters = []
    params = {}

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for single contributors_filter' do
    expected_filters =
      [
        { term: { 'contributors.value.keyword': 'Lastname, Firstname' } }
      ]
    params = { contributors_filter: ['Lastname, Firstname'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for multiple contributors_filter' do
    expected_filters =
      [
        { term: { 'contributors.value.keyword': 'Lastname, Firstname' } },
        { term: { 'contributors.value.keyword': 'Another name' } }
      ]
    params = { contributors_filter: ['Lastname, Firstname', 'Another name'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for single content_type_filter' do
    expected_filters =
      [
        { term: { content_type: 'cheese' } }
      ]
    params = { content_type_filter: ['cheese'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for multiple content_type_filter' do
    expected_filters =
      [
        { term: { content_type: 'cheese' } },
        { term: { content_type: 'ice cream' } }
      ]
    params = { content_type_filter: ['cheese', 'ice cream'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for single content_format_filter' do
    expected_filters =
      [
        { term: { format: 'cheese' } }
      ]
    params = { content_format_filter: ['cheese'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for multiple content_format_filter' do
    expected_filters =
      [
        { term: { format: 'cheese' } },
        { term: { format: 'ice cream' } }
      ]
    params = { content_format_filter: ['cheese', 'ice cream'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for single languages_filter' do
    expected_filters =
      [
        { term: { languages: 'cheese' } }
      ]
    params = { languages_filter: ['cheese'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for multiple languages_filter' do
    expected_filters =
      [
        { term: { languages: 'cheese' } },
        { term: { languages: 'ice cream' } }
      ]
    params = { languages_filter: ['cheese', 'ice cream'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  # literary form is only single value
  test 'filters query structure for literary_form_filter' do
    expected_filters =
      [
        { term: { literary_form: 'cheese' } }
      ]
    params = { literary_form_filter: 'cheese' }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for single subjects_filter' do
    expected_filters =
      [
        { term: { 'subjects.value.keyword': 'cheese' } }
      ]
    params = { subjects_filter: ['cheese'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
  end

  test 'filters query structure for multiple subjects_filter' do
    expected_filters =
      [
        { term: { 'subjects.value.keyword': 'cheese' } },
        { term: { 'subjects.value.keyword': 'ice cream' } }
      ]
    params = { subjects_filter: ['cheese', 'ice cream'] }

    assert_equal(expected_filters, Opensearch.new.filters(params))
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

  test 'can search by geopoint' do
    os = Opensearch.new
    os.instance_variable_set(:@params,
                             { geodistance: { latitude: '42.361145', longitude: '-71.057083', distance: '50mi' } })

    refute(os.matches.to_json.include?('{"multi_match":{"query":'))

    assert(
      os.query.to_json.include?('{"distance":"50mi","locations.geoshape":{"lat":"42.361145","lon":"-71.057083"}}')
    )
  end

  test 'can search for combination of geopoint and keyword' do
    os = Opensearch.new
    os.instance_variable_set(:@params,
                             { geodistance: { latitude: '42.361145', longitude: '-71.057083', distance: '50mi' },
                               q: 'rail stations' })

    assert(os.matches.to_json.include?('{"multi_match":{"query":"rail stations","fields":'))

    assert(
      os.query.to_json.include?('{"distance":"50mi","locations.geoshape":{"lat":"42.361145","lon":"-71.057083"}}')
    )
  end

  test 'can search by bounding box' do
    os = Opensearch.new
    os.instance_variable_set(:@params,
                             { geobox: { max_latitude: '42.886', min_latitude: '41.239',
                                         max_longitude: '-73.928', min_longitude: '-69.507' } })

    refute(os.matches.to_json.include?('{"multi_match":{"query"'))

    assert(
      os.query.to_json.include?('{"locations.geoshape":{"top":"42.886","bottom":"41.239","left":"-69.507","right":"-73.928"}}')
    )
  end

  test 'can search by bounding box and keyword' do
    os = Opensearch.new
    os.instance_variable_set(:@params,
                             { geobox: { max_latitude: '42.886', min_latitude: '41.239',
                                         max_longitude: '-73.928', min_longitude: '-69.507' },
                               q: 'rail stations' })

    assert(os.matches.to_json.include?('{"multi_match":{"query":"rail stations","fields":'))

    assert(
      os.query.to_json.include?('{"locations.geoshape":{"top":"42.886","bottom":"41.239","left":"-69.507","right":"-73.928"}}')
    )
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

  test 'build_query caps per_page at MAX_PAGE' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { per_page: Opensearch::MAX_PAGE + 100 })
    json = JSON.parse(os.build_query(0))
    assert_equal Opensearch::MAX_PAGE, json['size']
  end
end
