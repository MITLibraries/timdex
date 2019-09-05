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
                                    title
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('Popcorn Venus /', json['data']['search'].first['title'])

      # confirm non-requested fields don't return
      assert_nil(json['data']['search'].first['contentType'])
    end
  end

  test 'search with more returned' do
    VCR.use_cassette('graphql search popcorn') do
      post '/graphql', params: { query: '{
                                  search(searchterm: "popcorn") {
                                    title
                                    contentType
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('Popcorn Venus /', json['data']['search'].first['title'])
      assert_equal('Text', json['data']['search'].first['contentType'])
    end
  end

  test 'search with invalid parameters' do
    post '/graphql', params: { query: '{
                                search(searchterm: "popcorn") {
                                  yo
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

  test 'retrieve' do
    VCR.use_cassette('graphql retrieve popcorn') do
      post '/graphql', params: { query: '{
                                  recordId(id: "000346597") {
                                    identifier
                                    title
                                  }
                                }' }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('Popcorn Venus /', json['data']['recordId']['title'])
      assert_equal('000346597', json['data']['recordId']['identifier'])

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
