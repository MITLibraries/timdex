require 'test_helper'

class GraphqlControllerV2Test < ActionDispatch::IntegrationTest
  def setup
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:v2, true)
  end

  test 'graphqlv2 playground' do
    get '/playground'
    assert_equal(200, response.status)
  end

  test 'graphqlv2 ping' do
    post '/graphql', params: { query: '{ ping }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert_equal('Pong!', json['data']['ping'])
  end

  test 'graphqlv2 search' do
    VCR.use_cassette('graphql v2 search data') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "data") {
                                    records {
                                      title
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('Data for time series tutorial',
                   json['data']['search']['records'].first['title'])

      # confirm non-requested fields don't return
      assert_nil(json['data']['search']['records'].first['contentType'])
    end
  end

  test 'graphqlv2 search with more returned' do
    VCR.use_cassette('graphql v2 search data') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "data") {
                                    records {
                                      title
                                      contentType
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('Data for time series tutorial',
                   json['data']['search']['records'].first['title'])
      assert_equal('Dataset',
                   json['data']['search']['records'].first['contentType'].first)
    end
  end

  test 'graphqlv2 search with invalid parameters' do
    post '/graphql', params: { query: '{
                                search(searchterm: "popcorn") {
                                  records {
                                    yo
                                  }
                                }
                              }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert_equal("Field 'yo' doesn't exist on type 'Record'",
                 json['errors'].first['message'])
  end

  test 'graphqlv2 with no query' do
    post '/graphql'
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert_equal('No query string was present',
                 json['errors'].first['message'])
  end

  test 'graphqlv2 search hits' do
    VCR.use_cassette('graphql v2 search data') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "data") {
                                    hits
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(557, json['data']['search']['hits'])
    end
  end

  test 'graphqlv2 search score' do
    VCR.use_cassette('graphql v2 search data') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "data") {
                                    records {
                                      score
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('20.448364', json['data']['search']['records'].first['score'])
    end
  end

  test 'graphqlv2 search highlighted query terms' do
    VCR.use_cassette('graphql v2 search data') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "data") {
                                    records {
                                      highlight {
                                        matchedField
                                        matchedPhrases
                                      }
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal [{ 'matchedField' => 'summary', 'matchedPhrases' => ['<p>These are sample <span class="highlight">data</span> files to be used in the time series tutorial found here: <a href="https://github.com'] }, { 'matchedField' => 'citation', 'matchedPhrases' => ['Stevens, Abigail (2021): <span class="highlight">Data</span> for time series tutorial. Zenodo.'] }, { 'matchedField' => 'title.exact_value', 'matchedPhrases' => ['<span class="highlight">Data for time series tutorial</span>'] }, { 'matchedField' => 'title', 'matchedPhrases' => ['<span class="highlight">Data</span> for time series tutorial'] }],
                   json['data']['search']['records'].first['highlight']
    end
  end

  test 'graphqlv2 targeted search on simple field' do
    VCR.use_cassette('graphql v2 search title') do
      post '/graphql', params: { query: '{
                                  search(title: "spice") {
                                    records {
                                      title
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal "Spice it up! the best of Paquito D'Rivera.", json['data']['search']['records'].first['title']
    end
  end

  test 'graphqlv2 targeted search on nested field' do
    VCR.use_cassette('graphqlv2 search contributors') do
      post '/graphql', params: { query: '{
                                  search(contributors: "moon") {
                                    records {
                                      contributors {
                                        value
                                      }
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert json['data']['search']['records'].first['contributors'].any? { |c| c.has_value? 'Moon, Intae' }
    end
  end

  test 'graphqlv2 targeted search on multiple fields' do
    VCR.use_cassette('graphqlv2 search multiple fields') do
      post '/graphql', params: { query: '{
                                  search(title: "common", contributors: "mcternan", identifiers: "163565002X") {
                                    records {
                                      title
                                      contributors {
                                        value
                                      }
                                      identifiers {
                                        value
                                      }
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal 'A common table : 80 recipes and stories from my shared cultures /',
                   json['data']['search']['records'].first['title']
      assert json['data']['search']['records'].first['contributors'].any? { |c|
               c.has_value? 'McTernan, Cynthia Chen, author.'
             }
      assert json['data']['search']['records'].first['identifiers'].any? { |i| i.has_value? '163565002X (hardback)' }
    end
  end

  test 'graphqlv2 search aggregations' do
    VCR.use_cassette('graphql v2 search data') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "data") {
                                    aggregations {
                                      source {
                                        key
                                        docCount
                                      }
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('zenodo',
                   json['data']['search']['aggregations']['source']
                   .first['key'])
      assert_equal(242,
                   json['data']['search']['aggregations']['source']
                   .first['docCount'])
    end
  end

  test 'graphqlv2 search with source facet applied' do
    VCR.use_cassette('graphql v2 search a only alma') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "a",
                                    sourceFacet: "MIT Alma") {
                                    hits
                                    aggregations {
                                      source {
                                        key
                                        docCount
                                      }
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('mit alma',
                   json['data']['search']['aggregations']['source']
                   .first['key'])
      assert_equal(3,
                   json['data']['search']['aggregations']['source']
                   .first['docCount'])
    end
  end

  test 'graphqlv2 search with multiple subjects applied' do
    skip 'opensearch model is not updated to allow this yet'
    VCR.use_cassette('graphql v2 search multiple subjects') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "space",
                                        subjectsFacet: ["space and time.",
                                                   "quantum theory."]) {
                                    hits
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(36, json['data']['search']['hits'])
    end
  end

  test 'graphqlv2 search with invalid facet applied' do
    post '/graphql', params: { query: '{
                                search(searchterm: "wright",
                                  fake: "mit archivesspace") {
                                  hits
                                  aggregations {
                                    source {
                                      key
                                      docCount
                                    }
                                  }
                                }
                              }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert(json['errors'].first['message'].present?)
    assert_equal("Field 'search' doesn't accept argument 'fake'",
                 json['errors'].first['message'])
  end

  test 'graphqlv2 valid facets can result in no results' do
    skip 'opensearch model is not updated to allow this yet'
    VCR.use_cassette('graphql v2 legal facets can result in no results') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "wright",
                                    subjectsFacet: ["fake facet value"]) {
                                    hits
                                    aggregations {
                                      source {
                                        key
                                        docCount
                                      }
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(0, json['data']['search']['hits'])
    end
  end

  test 'graphqlv2 retrieve' do
    VCR.use_cassette('graphql v2 retrieve') do
      post '/graphql', params: { query: '{
                                  recordId(id: "mit:alma:990026671500206761") {
                                    timdexRecordId
                                    title
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert(json['data']['recordId']['title'].start_with?('Spice'))
      assert_equal('mit:alma:990026671500206761', json['data']['recordId']['timdexRecordId'])

      # confirm non-requested fields don't return
      assert_nil(json['data']['recordId']['literaryForm'])
    end
  end

  test 'graphqlv2 retrieve invalid field' do
    post '/graphql', params: { query: 'recordId(id: "stuff") {
                                stuff
                              }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert(json['errors'].first['message'].present?)
  end
end
