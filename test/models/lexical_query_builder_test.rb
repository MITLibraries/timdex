require 'test_helper'

class LexicalQueryBuilderTest < ActiveSupport::TestCase
  test 'matches citation' do
    builder = LexicalQueryBuilder.new
    params = { citation: 'foo' }

    assert(builder.build(params).to_json.include?('{"match":{"citation":"foo"}}'))
  end

  test 'matches title' do
    builder = LexicalQueryBuilder.new
    params = { title: 'foo' }

    assert(builder.build(params).to_json.include?('{"match":{"title":"foo"}}'))
  end

  test 'matches contributors' do
    builder = LexicalQueryBuilder.new
    params = { contributors: 'foo' }

    assert(builder.build(params).to_json.include?('{"match":{"contributors.value":"foo"}}'))
  end

  test 'matches funding_information' do
    builder = LexicalQueryBuilder.new
    params = { funding_information: 'foo' }

    assert(builder.build(params).to_json.include?('{"match":{"funding_information.funder_name":"foo"}}'))
  end

  test 'matches identifiers' do
    builder = LexicalQueryBuilder.new
    params = { identifiers: 'foo' }

    assert(builder.build(params).to_json.include?('{"match":{"identifiers.value":"foo"}}'))
  end

  test 'matches locations' do
    builder = LexicalQueryBuilder.new
    params = { locations: 'foo' }

    assert(builder.build(params).to_json.include?('{"match":{"locations.value":"foo"}}'))
  end

  test 'matches subjects' do
    builder = LexicalQueryBuilder.new
    params = { subjects: 'foo' }

    assert(builder.build(params).to_json.include?('{"match":{"subjects.value":"foo"}}'))
  end

  test 'matches everything' do
    builder = LexicalQueryBuilder.new
    params = { q: 'this', citation: 'here', title: 'is', contributors: 'a',
               funding_information: 'real', identifiers: 'search', locations: 'rest',
               subjects: 'assured,' }

    query_json = builder.build(params).to_json
    assert(query_json.include?('{"multi_match":{"query":"this","fields":'))
    assert(query_json.include?('{"match":{"citation":"here"}}'))
    assert(query_json.include?('{"match":{"title":"is"}}'))
    assert(query_json.include?('{"match":{"contributors.value":"a"}}'))
    assert(query_json.include?('{"match":{"funding_information.funder_name":"real"}}'))
    assert(query_json.include?('{"match":{"identifiers.value":"search"}}'))
    assert(query_json.include?('{"match":{"locations.value":"rest"}}'))
    assert(query_json.include?('{"match":{"subjects.value":"assured,"}}'))
  end

  test 'fulltext is included when requested' do
    builder = LexicalQueryBuilder.new
    params = { q: 'this' }

    assert(builder.build(params, true).to_json.include?('"fields":["alternate_titles","call_numbers","citation","contents","contributors.value","dates.value","edition","funding_information.*","identifiers.value","languages","locations.value","notes.value","numbering","publication_information","subjects.value","summary","title","fulltext"]'))
  end

  test 'fulltext is not included by default' do
    builder = LexicalQueryBuilder.new
    params = { q: 'this' }

    assert(builder.build(params, false).to_json.include?('"fields":["alternate_titles","call_numbers","citation","contents","contributors.value","dates.value","edition","funding_information.*","identifiers.value","languages","locations.value","notes.value","numbering","publication_information","subjects.value","summary","title"]'))
  end

  test 'can search by geopoint' do
    builder = LexicalQueryBuilder.new
    params = { geodistance: { latitude: '42.361145', longitude: '-71.057083', distance: '50mi' } }
    query = builder.build(params)

    refute(query.to_json.include?('{"multi_match":{"query":'))

    assert(
      query.to_json.include?('{"distance":"50mi","locations.geoshape":{"lat":"42.361145","lon":"-71.057083"}}')
    )
  end

  test 'can search for combination of geopoint and keyword' do
    builder = LexicalQueryBuilder.new
    params = { geodistance: { latitude: '42.361145', longitude: '-71.057083', distance: '50mi' },
               q: 'rail stations' }
    query = builder.build(params)

    assert(query.to_json.include?('{"multi_match":{"query":"rail stations","fields":'))

    assert(
      query.to_json.include?('{"distance":"50mi","locations.geoshape":{"lat":"42.361145","lon":"-71.057083"}}')
    )
  end

  test 'can search by bounding box' do
    builder = LexicalQueryBuilder.new
    params = { geobox: { max_latitude: '42.886', min_latitude: '41.239',
                         max_longitude: '-73.928', min_longitude: '-69.507' } }
    query = builder.build(params)

    refute(query.to_json.include?('{"multi_match":{"query"'))

    assert(
      query.to_json.include?('{"locations.geoshape":{"top":"42.886","bottom":"41.239","left":"-69.507","right":"-73.928"}}')
    )
  end

  test 'can search by bounding box and keyword' do
    builder = LexicalQueryBuilder.new
    params = { geobox: { max_latitude: '42.886', min_latitude: '41.239',
                         max_longitude: '-73.928', min_longitude: '-69.507' },
               q: 'rail stations' }
    query = builder.build(params)

    assert(query.to_json.include?('{"multi_match":{"query":"rail stations","fields":'))

    assert(
      query.to_json.include?('{"locations.geoshape":{"top":"42.886","bottom":"41.239","left":"-69.507","right":"-73.928"}}')
    )
  end
end
