require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  test 'valid token' do
    token = JWTWrapper.encode(user_id: users(:yo).id)
    get '/search?q=super+cool+search',
        headers: { 'Authorization': "Bearer #{token}" }
    assert_equal(200, response.status)
    assert_equal('[{"id": "aleph001"}, {"id": "aleph002"}]', response.body)
  end

  test 'invalid token' do
    token = JWTWrapper.encode(user_id: 'fakeid')
    get '/search?q=super+cool+search',
        headers: { 'Authorization': "Bearer #{token}" }
    assert_equal(401, response.status)
    assert_equal('{"error" : "invalid credentials"}', response.body)
  end

  test 'expired token' do
    token = Timecop.freeze(Time.zone.today - 1) do
      JWTWrapper.encode(user_id: users(:yo).id)
    end
    get '/search?q=super+cool+search',
        headers: { 'Authorization': "Bearer #{token}" }
    assert_equal(401, response.status)
    assert_equal('{"error" : "invalid credentials"}', response.body)
  end

  test 'ping with no token' do
    get '/ping'
    assert_equal(200, response.status)
    assert_equal('pong', response.body)
  end

  test 'ping with valid token' do
    token = JWTWrapper.encode(user_id: users(:yo).id)
    get '/ping', headers: { 'Authorization': "Bearer #{token}" }
    assert_equal(200, response.status)
    assert_equal('pong', response.body)
  end
end
