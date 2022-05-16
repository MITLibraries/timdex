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
      assert_equal('Data for Haqdarshak: Leveraging Technology and Entrepreneurship to Increase Access to Welfare Programs',
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
      assert_equal('Data for Haqdarshak: Leveraging Technology and Entrepreneurship to Increase Access to Welfare Programs',
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
      assert_equal(73, json['data']['search']['hits'])
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
      assert_equal('abdul latif jameel poverty action lab dataverse',
                   json['data']['search']['aggregations']['source']
                   .first['key'])
      assert_equal(73,
                   json['data']['search']['aggregations']['source']
                   .first['docCount'])
    end
  end

  test 'graphqlv2 search with source facet applied' do
    VCR.use_cassette('graphql v2 search a only alma') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "a",
                                    source: "MIT Alma") {
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
                                        subjects: ["space and time.",
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
                                    subjects: ["fake facet value"]) {
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
