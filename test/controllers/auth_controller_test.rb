require 'test_helper'

class AuthControllerTest < ActionDispatch::IntegrationTest
  test 'valid credentials returns JWT' do
    u = users(:yo)
    b = Base64.encode64(u.email + ':123greetings')
    get '/api/v1/auth', headers: { Authorization: "Basic #{b}" }
    assert_equal(200, response.status)
    assert_equal(u.id, JwtWrapper.decode(JSON.parse(response.body))['user_id'])
  end

  test 'invalid credentials' do
    get '/api/v1/auth'
    assert_equal(401, response.status)
    assert_equal('{"error" : "invalid credentials"}', response.body)
  end
end
