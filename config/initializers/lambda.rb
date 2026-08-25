require 'aws-sdk-lambda'
require 'aws_auth'
require 'aws_config_validator'

def validate_lambda_config!
  AwsConfigValidator.validate_lambda_config
end

def lambda_credentials
  if ENV['AWS_SESSION_TOKEN'].present?
    Rails.logger.debug 'Configuring Lambda client with temporary static credentials (session token)'
    return AwsAuth.static_credentials
  end

  Rails.logger.debug 'Configuring Lambda client with assumed role credentials'
  AwsAuth.assume_role_credentials(role_session_name: 'timdex-lambda')
end

def configure_lambda_client
  validate_lambda_config!

  Rails.logger.debug 'Configuring AWS Lambda client'

  options = { region: ENV.fetch('AWS_REGION', 'us-east-1') }
  options[:credentials] = lambda_credentials

  # AWS SDK sets this env in prod. However, we need to conditionally set it for tests so VCR can
  # intercept the requests with a fake URL.
  if ENV['AWS_ENDPOINT_URL_LAMBDA'].present?
    Rails.logger.debug 'Using AWS_ENDPOINT_URL_LAMBDA override for Lambda client endpoint'
    options[:endpoint] = ENV['AWS_ENDPOINT_URL_LAMBDA']
  end
  Aws::Lambda::Client.new(options)
end

Timdex::LambdaClient = configure_lambda_client
