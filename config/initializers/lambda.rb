require 'aws-sdk-lambda'

def configure_lambda_client
  Aws::Lambda::Client.new(
    region: ENV.fetch('AWS_REGION', 'us-east-1'),
    access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
    secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY')
  )
end

Timdex::LambdaClient = configure_lambda_client
