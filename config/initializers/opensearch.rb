require 'faraday_middleware/aws_sigv4'

def configure_opensearch
  if ENV['AWS_OPENSEARCH'] == 'true'
    aws_os_client
  else
    os_client
  end
end

def os_client
  OpenSearch::Client.new log: ENV.fetch('OPENSEARCH_LOG', false)
end

def aws_os_client
  OpenSearch::Client.new log: ENV.fetch('OPENSEARCH_LOG', false), url: ENV['OPENSEARCH_URL'] do |config|
    # personal keys use expiring credentials with tokens
    if ENV.fetch('AWS_OPENSEARCH_SESSION_TOKEN', false)
      config.request :aws_sigv4,
                      service: 'es',
                      region: ENV['AWS_REGION'],
                      access_key_id: ENV['AWS_OPENSEARCH_ACCESS_KEY_ID'],
                      secret_access_key: ENV['AWS_OPENSEARCH_SECRET_ACCESS_KEY'],
                      session_token: ENV['AWS_OPENSEARCH_SESSION_TOKEN']
    # application keys don't use tokens
    else
      config.request :aws_sigv4,
                      service: 'es',
                      region: ENV['AWS_REGION'],
                      access_key_id: ENV['AWS_OPENSEARCH_ACCESS_KEY_ID'],
                      secret_access_key: ENV['AWS_OPENSEARCH_SECRET_ACCESS_KEY']
    end
  end
end

Timdex::OSClient = configure_opensearch
