require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  test 'valid token' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('q super cool search') do
      get '/api/v1/search?q=super+cool+search',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(21_502, json['hits'])
    end
  end

  test 'invalid token succeeds and includes throttle information' do
    token = JwtWrapper.encode(user_id: 'fakeid')
    VCR.use_cassette('invalid token') do
      get '/api/v1/search?q=super+cool+search',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(100, json['request_limit'])
    end
  end

  test 'expired token succeeds and includes throttle information' do
    token = Timecop.freeze(Time.zone.today - 1) do
      JwtWrapper.encode(user_id: users(:yo).id)
    end
    VCR.use_cassette('expired token') do
      get '/api/v1/search?q=super+cool+search',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(100, json['request_limit'])
    end
  end

  test 'ping with no token' do
    get '/api/v1/ping'
    assert_equal(200, response.status)
    assert_equal('pong', JSON.parse(response.body))
  end

  test 'ping with valid token' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    get '/api/v1/ping', headers: { Authorization: "Bearer #{token}" }
    assert_equal(200, response.status)
    assert_equal('pong', JSON.parse(response.body))
  end

  test 'valid record' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('record 001714562') do
      get '/api/v1/record/001714562',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('001714562', json['id'])
      assert_equal('Marvel zombies /', json['title'])
    end
  end

  test 'invalid record' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('record asdf') do
      get '/api/v1/record/asdf',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(404, response.status)
    end
  end

  test 'record with a period in the id' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('record period') do
      get '/api/v1/record/MIT:archivespace:MC.0044',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('MIT:archivespace:MC.0044', json['id'])
    end
  end

  test 'pagination' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('pagination') do
      get '/api/v1/search?q=marvel',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002312360', json['results'][0]['id'])

      get '/api/v1/search?q=marvel&page=2',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002611432', json['results'][0]['id'])

      get '/api/v1/search?q=marvel&page=10',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002602394', json['results'][0]['id'])

      get '/api/v1/search?q=marvel&page=25',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('Invalid page parameter: requested page past last result',
                   json['error'])

      get '/api/v1/search?q=marvel&page=400',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(400, response.status)
      json = JSON.parse(response.body)
      assert_nil(json['hits'])
      assert_equal('Invalid page: max 200',
                   json['error'])
    end
  end

  test 'filtering parameters that take multiple values' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('filtering multiple values') do
      get '/api/v1/search?q=marvel',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002312360', json['results'][0]['id'])

      get '/api/v1/search?q=marvel&subject[]=Graphic%20Novels.',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(20, json['hits'])
      assert_equal('002295630', json['results'][0]['id'])

      get '/api/v1/search?q=marvel&subject[]=Graphic%20Novels.&subject[]=science%20fiction%20comic%20books,%20strips,%20etc.',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(11, json['hits'])
      assert_equal('002759156', json['results'][0]['id'])
    end
  end

  test 'filtering parameters that single a value' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('filtering single value') do
      get '/api/v1/search?q=marvel',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002312360', json['results'][0]['id'])

      get '/api/v1/search?q=marvel&literary_form=fiction',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(227, json['hits'])
      assert_equal('002312360', json['results'][0]['id'])
    end
  end
end
