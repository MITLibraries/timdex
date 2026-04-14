# OpensearchConfigValidator validates required environment variables for OpenSearch connections
# This is a separate class to allow for clean testing of initialization logic.
class OpensearchConfigValidator
  # Validates that all required environment variables for AWS AOSS are present
  # @raise [RuntimeError] if any required variable is missing
  def self.validate_aws_aoss_config
    # Always required for AWS AOSS
    required_vars = {
      'OPENSEARCH_URL' => ENV.fetch('OPENSEARCH_URL', nil),
      'AWS_REGION' => ENV.fetch('AWS_REGION', nil),
      'AWS_ACCESS_KEY_ID' => ENV.fetch('AWS_ACCESS_KEY_ID', nil),
      'AWS_SECRET_ACCESS_KEY' => ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
    }

    # Required only when AWS_SESSION_TOKEN is not present (using role assumption)
    required_vars['AWS_AOSS_ROLE_ARN'] = ENV.fetch('AWS_AOSS_ROLE_ARN', nil) if ENV['AWS_SESSION_TOKEN'].blank?

    missing_vars = required_vars.select { |_key, value| value.blank? }.keys

    return unless missing_vars.any?

    raise "AWS AOSS Config Error: These required environment variables are not set: #{missing_vars.join(', ')}"
  end

  # Validates that all required environment variables for AWS OpenSearch Service are present
  # @raise [RuntimeError] if any required variable is missing
  def self.validate_aws_os_config
    required_vars = {
      'OPENSEARCH_URL' => ENV.fetch('OPENSEARCH_URL', nil),
      'AWS_REGION' => ENV.fetch('AWS_REGION', nil),
      'AWS_ACCESS_KEY_ID' => ENV.fetch('AWS_ACCESS_KEY_ID', nil),
      'AWS_SECRET_ACCESS_KEY' => ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
    }

    missing_vars = required_vars.select { |_key, value| value.blank? }.keys

    return unless missing_vars.any?

    raise "AWS OpenSearch Config Error: These required environment variables are not set: #{missing_vars.join(', ')}"
  end
end
