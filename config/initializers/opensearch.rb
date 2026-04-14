require 'faraday_middleware/aws_sigv4' if ENV['AWS_OPENSEARCH'] == 'true' && ENV.fetch('AWS_AOSS', 'false') == 'false'
require 'opensearch-aws-sigv4'
require 'aws-sigv4'
require 'opensearch_config_validator'

# Helper method to parse OPENSEARCH_LOG as a boolean
# Environment variables are always strings, so 'false' is truthy
# Only treat as true if explicitly set to 'true' (case-insensitive)
def opensearch_logging_enabled?
  ENV.fetch('OPENSEARCH_LOG', '').downcase == 'true'
end

# Priority is given to AWS AOSS, then AWS OpenSearch, and finally vanilla OpenSearch
def configure_opensearch
  if ENV['AWS_AOSS'] == 'true'
    OpensearchConfigValidator.validate_aws_aoss_config
    aws_aoss_client
  elsif ENV['AWS_OPENSEARCH'] == 'true'
    OpensearchConfigValidator.validate_aws_os_config
    aws_os_client
  else
    os_client
  end
end

# os_client is used to connect to a standard OpenSearch cluster that does not require AWS SigV4 signing for
# authentication. It creates a new OpenSearch::Client with logging enabled based on the OPENSEARCH_LOG
# environment variable.
#
# @return [OpenSearch::Client] a client for connecting to a standard OpenSearch cluster
# @note This is mostly used for connecting to a locally running OpenSearch instance
def os_client
  OpenSearch::Client.new log: opensearch_logging_enabled?
end

# aws_os_client is used to connect to AWS OpenSearch Service which requires AWS SigV4 signing for authentication. It
# creates a new OpenSearch::Client and configures it to use the aws_sigv4 middleware for request signing. The middleware
# is configured with the AWS region, access key ID, secret access key, and optionally a session token if using temporary
# credentials. The OPENSEARCH_URL environment variable is used to specify the endpoint of the OpenSearch cluster.
#
# @return [OpenSearch::Client] a client for connecting to AWS OpenSearch Service (ES)
# @note This is the legacy method for this application and will be removed when we migrate to AOSS.
# @note AWS OpenSearch Service can use long-lived access keys, unlike AWS AOSS which requires temporary credentials
# obtained by assuming a role.
def aws_os_client
  OpenSearch::Client.new log: opensearch_logging_enabled?, url: ENV.fetch('OPENSEARCH_URL', nil) do |config|
    Rails.logger.debug "Configuring Legacy AWS OpenSearch Service client"
    # personal keys use expiring credentials with tokens
    if ENV['AWS_SESSION_TOKEN'].present?
      Rails.logger.debug 'Using temporary credentials with session token'
      config.request :aws_sigv4,
                     service: 'es',
                     region: ENV.fetch('AWS_REGION', nil),
                     access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
                     secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
                     session_token: ENV['AWS_SESSION_TOKEN']
    # application keys don't use tokens
    else
      Rails.logger.debug 'Using long-lived credentials without session token'
      config.request :aws_sigv4,
                     service: 'es',
                     region: ENV.fetch('AWS_REGION', nil),
                     access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
                     secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
    end
  end
end

# aws_aoss_client is used to connect to AWS OpenSearch Serverless (AOSS) which has a different authentication mechanism
# than AWS OpenSearch Service. It uses AWS SigV4 signing for authentication, and the OpenSearch::Aws::Sigv4Client is
# specifically designed to handle this type of authentication.
#
# @return [OpenSearch::Aws::Sigv4Client] a client for connecting to AWS OpenSearch Serverless (AOSS)
# @note this configuration uses temporary credentials obtained by assuming a role or via the AWS console, unlike
# AWS OpenSearch Service which can use long-lived access keys directly.
def aws_aoss_client
  Rails.logger.debug "Configuring AWS AOSS client"

  signer = Aws::Sigv4::Signer.new(
    service: 'aoss',
    region: ENV.fetch('AWS_REGION', nil),
    credentials_provider: credentials
  )

  OpenSearch::Aws::Sigv4Client.new(
    {
      host: ENV.fetch('OPENSEARCH_URL', nil),
      log: opensearch_logging_enabled?
    },
    signer
  )
end

def credentials
  if ENV.fetch('AWS_SESSION_TOKEN', false).present?
    Rails.logger.debug 'Using temporary credentials with session token'
    temporary_credentials
  else
    Rails.logger.debug 'Using long-lived credentials and assuming role'
    assume_role_credentials
  end
end

# personal keys use expiring credentials with tokens, so we use them directly without assuming a role
# application keys use long-lived credentials and assume a role to get temporary credentials for AOSS
def temporary_credentials
  Aws::Credentials.new(
    ENV.fetch('AWS_ACCESS_KEY_ID', nil),
    ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
    ENV.fetch('AWS_SESSION_TOKEN', nil)
  )
end

# AWS AOSS uses temporary credentials that are obtained by assuming a role. The
# Aws::AssumeRoleCredentials class is used to get these temporary credentials. It requires the ARN of
# the role to assume, a session name, and a client for the AWS Security Token Service (STS) which is
# used to perform the AssumeRole operation. It uses the AWS region and access keys from the
# environment variables to create the STS client. When the session token expires, the
# Aws::AssumeRoleCredentials will automatically refresh the credentials by calling AssumeRole again.
def assume_role_credentials
  Aws::AssumeRoleCredentials.new(
    role_arn: ENV.fetch('AWS_AOSS_ROLE_ARN', nil),
    role_session_name: 'timdex-opensearch',
    client: Aws::STS::Client.new(
      region: ENV.fetch('AWS_REGION', nil),
      access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
    )
  )
end

Timdex::OSClient = configure_opensearch
