class Rack::Attack

  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blacklisting and
  # whitelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!

  # Throttle all requests by IP
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip',
           limit: (ENV.fetch('REQUESTS_PER_PERIOD') { 100 }).to_i,
           period: (ENV.fetch('REQUEST_PERIOD') { 1 }).to_i.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  ### Prevent Brute-Force Login Attacks ###

  # The most common brute-force login attack is a brute-force password
  # attack where an attacker simply tries a large number of emails and
  # passwords to see if any credentials match.
  #
  # Another common method of attack is to use a swarm of computers with
  # different IPs to try brute-forcing a password for a specific account.
  # We aren't currently handling this second case.

  # Throttle POST requests to /login by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/api/v1/auth'
      req.ip
    end
  end

  # If the reqeust includes a valid JWT token, ignore all other throttle
  # conditions. Any truthy response results in the request being safelisted.
  Rack::Attack.safelist("mark any authenticated access safe") do |request|
    if request.has_header?('HTTP_AUTHORIZATION')

      strategy, token = request.fetch_header('HTTP_AUTHORIZATION').split(' ')

      # No token or not even close to valid
      if (strategy || '').downcase != 'bearer'
        false
      else

        # This rescue catches expired tokens and will result in
        # a non-truthy return in the next condition.
        claims = JWTWrapper.decode(token) rescue nil

        # Expired token from above or somehow it doesn't have a user_id in it
        if !claims || !claims.has_key?('user_id')
          false

        # Returns truthy and safelists if the user is valid
        else
          User.find_by_id claims['user_id']
        end
      end

    end
  end

  # Provide userful information when throttle is triggered so users know what
  # happened. Rack-attack provides very little by default becaust it assumes
  # bad intent. We are assuming good intent and thus provide users with info
  # about how many requests are allowed in a time period and how to remove
  # those restrictions by registering.
  Rack::Attack.throttled_response = lambda do |env|
    match_data = env['rack.attack.match_data']
    now = match_data[:epoch_time]

    headers = {
      'Content-Type' => 'application/json',
      'RateLimit-Limit' => match_data[:limit].to_s,
      'RateLimit-Remaining' => '0',
      'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
    }

    body = {
      :error => 'Throttled. Register for an account for unlimited access.',
      :request_limit => match_data[:limit].to_s,
      :request_count => match_data[:count].to_s,
      :limit_info => 'Register for a free account and provide your JWT token to remove all request limitations.',
      :token_provided => 'If you provided a JWT token, it was either invalid or expired. Please revisit documentation and send us an email if you need assistance with these limits.'
    }

    [ 429, headers, [body.to_json]]
  end

  # Log when throttles are triggered
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
    @@rack_logger ||= ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
    @@rack_logger.info{[
      "[#{payload[:request].env['rack.attack.match_type']}]",
      "[#{payload[:request].env['rack.attack.matched']}]",
      "[#{payload[:request].env['rack.attack.match_discriminator']}]",
      "[#{payload[:request].env['rack.attack.throttle_data']}]",
      ].join(' ') }
  end
end
