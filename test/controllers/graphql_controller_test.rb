require 'test_helper'

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  test 'playground' do
    get '/playground'
    assert_equal(200, response.status)
  end

  test 'ping' do
    post '/graphql', params: { query: '{ ping }' }
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert_equal('Pong!', json['data']['ping'])
  end

  test 'search' do
    VCR.use_cassette('graphql search popcorn') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "popcorn") {
                                    records {
                                      title
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('Popcorn Industry Profile: Belgium',
                   json['data']['search']['records'].first['title'])

      # confirm non-requested fields don't return
      assert_nil(json['data']['search']['records'].first['contentType'])
    end
  end

  test 'search with more returned' do
    VCR.use_cassette('graphql search popcorn') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "popcorn") {
                                    records {
                                      title
                                      contentType
                                    }
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('Popcorn Industry Profile: Belgium',
                   json['data']['search']['records'].first['title'])
      assert_equal('Text',
                   json['data']['search']['records'].first['contentType'])
    end
  end

  test 'search with invalid parameters' do
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

  test 'with no query' do
    post '/graphql'
    assert_equal(200, response.status)
    json = JSON.parse(response.body)
    assert_equal('No query string was present',
                 json['errors'].first['message'])
  end

  test 'search hits' do
    VCR.use_cassette('graphql search popcorn') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "popcorn") {
                                    hits
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(113, json['data']['search']['hits'])
    end
  end

  test 'search aggregations' do
    VCR.use_cassette('graphql search popcorn') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "popcorn") {
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
      assert_equal('mit aleph',
                   json['data']['search']['aggregations']['source']
                   .first['key'])
      assert_equal(113,
                   json['data']['search']['aggregations']['source']
                   .first['docCount'])
    end
  end

  test 'search with source facet applied' do
    VCR.use_cassette('graphql search wright only aspace') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "wright",
                                    source: "mit archivesspace") {
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
      assert_equal('mit archivesspace',
                   json['data']['search']['aggregations']['source']
                   .first['key'])
      assert_equal(1,
                   json['data']['search']['aggregations']['source']
                   .first['docCount'])
    end
  end

  test 'search with multiple subjects applied' do
    VCR.use_cassette('graphql search multiple subjects') do
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

  test 'search with invalid facet applied' do
    VCR.use_cassette('graphql search wright fake facet') do
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
  end

  test 'valid facets can result in no results' do
    VCR.use_cassette('graphql legal facets can result in no results') do
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

  test 'retrieve' do
    VCR.use_cassette('graphql retrieve') do
      post '/graphql', params: { query: '{
                                  recordId(id: "001245816") {
                                    identifier
                                    title
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert(json['data']['recordId']['title'].start_with?('Popcorn Moms'))
      assert_equal('001245816', json['data']['recordId']['identifier'])

      # confirm non-requested fields don't return
      assert_nil(json['data']['recordId']['literaryForm'])
    end
  end

  test 'retrieve invalid field' do
    VCR.use_cassette('graphql retrieve error') do
      post '/graphql', params: { query: 'recordId(id: "stuff") {
                                  stuff
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert(json['errors'].first['message'].present?)
    end
  end
end
