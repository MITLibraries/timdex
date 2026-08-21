# AwsAuth centralizes AWS credential and role-assumption helpers shared by
# OpenSearch and Lambda initialization.
module AwsAuth
  module_function

  def validate_required_vars!(required_vars, error_prefix:)
    missing_vars = required_vars.select { |_key, value| value.blank? }.keys

    return unless missing_vars.any?

    raise "#{error_prefix}: These required environment variables are not set: #{missing_vars.join(', ')}"
  end

  def validate_base_aws_config!(error_prefix:)
    validate_required_vars!(
      {
        'AWS_REGION' => ENV.fetch('AWS_REGION', nil),
        'AWS_ACCESS_KEY_ID' => ENV.fetch('AWS_ACCESS_KEY_ID', nil),
        'AWS_SECRET_ACCESS_KEY' => ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
      },
      error_prefix: error_prefix
    )
  end

  def role_arn_present?
    ENV['AWS_ROLE_ARN'].present?
  end

  def static_credentials
    Aws::Credentials.new(
      ENV.fetch('AWS_ACCESS_KEY_ID', nil),
      ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
      ENV.fetch('AWS_SESSION_TOKEN', nil)
    )
  end

  def sts_client
    options = {
      region: ENV.fetch('AWS_REGION', 'us-east-1'),
      access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
    }
    options[:session_token] = ENV['AWS_SESSION_TOKEN'] if ENV['AWS_SESSION_TOKEN'].present?

    Aws::STS::Client.new(options)
  end

  def assume_role_credentials(role_session_name:)
    Aws::AssumeRoleCredentials.new(
      role_arn: ENV.fetch('AWS_ROLE_ARN', nil),
      role_session_name: role_session_name,
      client: sts_client
    )
  end
end
