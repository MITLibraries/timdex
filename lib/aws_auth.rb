# AwsAuth centralizes AWS credential and role-assumption helpers shared by
# OpenSearch and Lambda initialization.
#
# It supports two auth patterns:
# 1) direct static credentials from environment variables
# 2) temporary assumed-role credentials via AWS STS
module AwsAuth
  module_function

  # Builds static credentials directly from environment variables.
  #
  # @return [Aws::Credentials] Credentials built from AWS_ACCESS_KEY_ID,
  #   AWS_SECRET_ACCESS_KEY, and optional AWS_SESSION_TOKEN.
  def static_credentials
    Aws::Credentials.new(
      ENV.fetch('AWS_ACCESS_KEY_ID', nil),
      ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
      ENV.fetch('AWS_SESSION_TOKEN', nil)
    )
  end

  # Builds an AWS STS client used for role-assumption flows.
  #
  # Region defaults to us-east-1 when AWS_REGION is not set.
  # Optional AWS_SESSION_TOKEN is forwarded when present.
  #
  # @return [Aws::STS::Client] Configured STS client instance.
  def sts_client
    options = {
      region: ENV.fetch('AWS_REGION', 'us-east-1'),
      access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
    }
    options[:session_token] = ENV['AWS_SESSION_TOKEN'] if ENV['AWS_SESSION_TOKEN'].present?

    Aws::STS::Client.new(options)
  end

  # Builds auto-refreshing assumed-role credentials backed by STS.
  #
  # @param role_session_name [String] Session identifier used in STS and
  #   CloudTrail for traceability.
  # @return [Aws::AssumeRoleCredentials] Refreshing credentials provider.
  def assume_role_credentials(role_session_name:)
    Aws::AssumeRoleCredentials.new(
      role_arn: ENV.fetch('AWS_ROLE_ARN', nil),
      role_session_name: role_session_name,
      client: sts_client
    )
  end
end
