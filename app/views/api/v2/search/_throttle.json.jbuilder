if request.env['rack.attack.throttle_data']
  json.request_limit request.env['rack.attack.throttle_data']['req/ip'][:limit]
  json.request_count request.env['rack.attack.throttle_data']['req/ip'][:count]
  json.limit_info 'Register for a free account and provide your JWT token to remove all request limitations.'
end
