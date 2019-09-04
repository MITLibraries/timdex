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
end
