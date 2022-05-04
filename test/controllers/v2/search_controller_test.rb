require 'test_helper'

class SearchControllerV2Test < ActionDispatch::IntegrationTest
  test 'valid token' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('v2 q Glass') do
      get '/api/v2/search?q=Glass',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(1, json['hits']['value'])
    end
  end

  test 'invalid token succeeds and includes throttle information' do
    token = JwtWrapper.encode(user_id: 'fakeid')
    VCR.use_cassette('v2 invalid token') do
      get '/api/v2/search?q=Glass',
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
    VCR.use_cassette('v2 expired token') do
      get '/api/v2/search?q=Glass',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(100, json['request_limit'])
    end
  end

  test 'ping with no token' do
    get '/api/v2/ping'
    assert_equal(200, response.status)
    assert_equal('pong', JSON.parse(response.body))
  end

  test 'ping with valid token' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    get '/api/v2/ping', headers: { Authorization: "Bearer #{token}" }
    assert_equal(200, response.status)
    assert_equal('pong', JSON.parse(response.body))
  end

  test 'info' do
    VCR.use_cassette('v2 info') do
      get '/api/v2/info'
      assert_equal(200, response.status)
      assert_equal('opensearch', JSON.parse(response.body)['distribution'])
    end
  end

  test 'valid record' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('v2 record mit:alma:990026671500206761') do
      get '/api/v2/record/mit:alma:990026671500206761',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('mit:alma:990026671500206761', json['id'])
      assert_equal('Spice it up! the best of Paquito D\'Rivera.', json['title'])
    end
  end

  test 'invalid record' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('v2 record asdf') do
      get '/api/v2/record/asdf',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(404, response.status)
    end
  end

  test 'record with a period in the id' do
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('v2 record period') do
      get '/api/v2/record/mit:archivesspace:VC.0002',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal('mit:archivesspace:VC.0002', json['id'])
    end
  end

  test 'pagination' do
    skip 'we need more test data to effectively test pagination'
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('v2 pagination') do
      get '/api/v2/search?q=marvel',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002312360', json['results'][0]['id'])

      get '/api/v2/search?q=marvel&page=2',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002611432', json['results'][0]['id'])

      get '/api/v2/search?q=marvel&page=10',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002602394', json['results'][0]['id'])

      get '/api/v2/search?q=marvel&page=25',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('Invalid page parameter: requested page past last result',
                   json['error'])

      get '/api/v2/search?q=marvel&page=400',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(400, response.status)
      json = JSON.parse(response.body)
      assert_nil(json['hits'])
      assert_equal('Invalid page: max 200',
                   json['error'])
    end
  end

  test 'filtering parameters that take multiple values' do
    skip 'we need more test data to effectively test filtering'
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('v2 filtering multiple values') do
      get '/api/v2/search?q=marvel',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002312360', json['results'][0]['id'])

      get '/api/v2/search?q=marvel&subject[]=Graphic%20Novels.',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(20, json['hits'])
      assert_equal('002295630', json['results'][0]['id'])

      get '/api/v2/search?q=marvel&subject[]=Graphic%20Novels.&subject[]=science%20fiction%20comic%20books,%20strips,%20etc.',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(11, json['hits'])
      assert_equal('002759156', json['results'][0]['id'])
    end
  end

  test 'filtering parameters that single a value' do
    skip 'we need more test data to effectively test filtering'
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('v2 filtering single value') do
      get '/api/v2/search?q=marvel',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(394, json['hits'])
      assert_equal('002312360', json['results'][0]['id'])

      get '/api/v2/search?q=marvel&literary_form=fiction',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)
      assert_equal(227, json['hits'])
      assert_equal('002312360', json['results'][0]['id'])
    end
  end

  test 'core fields are returned' do
    skip 'We need more fixture data to test all of these fields, and we need to determine which will be core in V2'
    token = JwtWrapper.encode(user_id: users(:yo).id)
    VCR.use_cassette('v2 q Glass') do
      get '/api/v2/search?q=Glass',
          headers: { Authorization: "Bearer #{token}" }
      assert_equal(200, response.status)
      json = JSON.parse(response.body)

      assert(json['results'].first['id'].present?)
      assert(json['results'].first['identifiers'].present?)
      assert(json['results'].first['source'].present?)
      assert(json['results'].first['source_link'].present?)
      assert(json['results'].first['title'].present?)
      assert(json['results'].first['alternate_titles'].present?)
      assert(json['results'].first['contributors'].present?)
      assert(json['results'].first['publication_information'].present?)
      assert(json['results'].first['dates'].present?)
      assert(json['results'].first['notes'].present?)
      assert(json['results'].first['contents'].present?)
      assert(json['results'].first['content_type'].present?)
      assert(json['results'].first['call_numbers'].present?)
      assert(json['results'].first['citation'].present?)
      assert(json['results'].first['edition'].present?)
      assert(json['results'].first['file_formats'].present?)
      assert(json['results'].first['format'].present?)
      assert(json['results'].first['funding_information'].present?)
      assert(json['results'].first['holdings'].present?)
      assert(json['results'].first['languages'].present?)
      assert(json['results'].first['links'].present?)
      assert(json['results'].first['literary_form'].present?)
      assert(json['results'].first['locations'].present?)
      assert(json['results'].first['numbering'].present?)
      assert(json['results'].first['physical_description'].present?)
      assert(json['results'].first['publication_frequency'].present?)
      assert(json['results'].first['related_items'].present?)
      assert(json['results'].first['rights'].present?)
      assert(json['results'].first['subjects'].present?)
      assert(json['results'].first['summary'].present?)
    end
  end
end
