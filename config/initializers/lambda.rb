require 'aws-sdk-lambda'

def configure_lambda_client
  options = {
    region: ENV.fetch('AWS_REGION', 'us-east-1'),
    access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
    secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY')
  }
  options[:session_token] = ENV['AWS_SESSION_TOKEN'] if ENV['AWS_SESSION_TOKEN'].present?

  # AWS SDK sets this env in prod. However, we need to conditionally set it for tests so VCR can
  # intercept the requests with a fake URL.
  options[:endpoint] = ENV['AWS_ENDPOINT_URL_LAMBDA'] if ENV['AWS_ENDPOINT_URL_LAMBDA'].present?
  Aws::Lambda::Client.new(options)
end

Timdex::LambdaClient = configure_lambda_client
