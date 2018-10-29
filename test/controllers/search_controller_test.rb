require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  test 'valid token' do
    token = JWTWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('q super cool search') do
      get '/search?q=super+cool+search',
          headers: { 'Authorization': "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(40, json['hits'])
    end
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

  test 'valid record' do
    token = JWTWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('record 001714562') do
      get '/record/001714562',
          headers: { 'Authorization': "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('001714562', json['id'])
      assert_equal('Marvel zombies /', json['title'])
    end
  end

  test 'invalid record' do
    token = JWTWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('record asdf') do
      get '/record/asdf',
          headers: { 'Authorization': "Bearer #{token}" }
      assert_equal(404, response.status)
    end
  end
end
