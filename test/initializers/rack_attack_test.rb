require 'test_helper'

class RackAttackTest < ActiveSupport::TestCase
  test 'throttled_responder accepts Rack::Attack::Request and returns 429 response' do
    env = {
      'rack.attack.match_data' => {
        limit: 100,
        count: 101,
        period: 60,
        epoch_time: 1_700_000_000
      }
    }

    request = Rack::Attack::Request.new(env)

    status, headers, body = Rack::Attack.throttled_responder.call(request)

    assert_equal 429, status
    assert_equal 'application/json', headers['Content-Type']
    assert_equal '100', headers['RateLimit-Limit']
    assert_equal '0', headers['RateLimit-Remaining']
    assert_equal '1700000040', headers['RateLimit-Reset']

    parsed_body = JSON.parse(body.first)
    assert_equal '100', parsed_body['request_limit']
    assert_equal '101', parsed_body['request_count']
    assert_equal true, parsed_body.key?('error')
  end

  test 'safelist allows authenticated request with valid bearer token and user' do
    user = users(:yo)
    request = Rack::Attack::Request.new('HTTP_AUTHORIZATION' => 'Bearer valid.token')

    JwtWrapper.stubs(:decode).with('valid.token').returns({ 'user_id' => user.id })

    assert_equal true, Rack::Attack.configuration.safelisted?(request)
  end

  test 'safelist rejects invalid bearer token' do
    request = Rack::Attack::Request.new('HTTP_AUTHORIZATION' => 'Bearer invalid.token')

    JwtWrapper.stubs(:decode).with('invalid.token').raises(JWT::DecodeError)

    assert_equal false, Rack::Attack.configuration.safelisted?(request)
  end

  test 'safelist rejects non-bearer authorization strategy' do
    request = Rack::Attack::Request.new('HTTP_AUTHORIZATION' => 'Basic abc123')

    assert_equal false, Rack::Attack.configuration.safelisted?(request)
  end
end
