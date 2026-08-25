# AwsConfigValidator validates AWS-related environment configuration for
# OpenSearch and Lambda initialization.
#
# Validation is split by integration pathway:
# 1) Lambda runtime credentials
# 2) AWS AOSS (OpenSearch Serverless)
# 3) AWS-managed OpenSearch
class AwsConfigValidator
  class << self
    # Validates required Lambda credential environment variables.
    #
    # AWS_ROLE_ARN becomes required only when AWS_SESSION_TOKEN is not present.
    # This supports both temporary session-token auth and role-assumption auth.
    #
    # @return [nil]
    # @raise [RuntimeError] when required env vars are missing.
    def validate_lambda_config
      required_vars = {
        'AWS_ACCESS_KEY_ID' => ENV.fetch('AWS_ACCESS_KEY_ID', nil),
        'AWS_SECRET_ACCESS_KEY' => ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
      }

      required_vars['AWS_ROLE_ARN'] = ENV.fetch('AWS_ROLE_ARN', nil) if ENV['AWS_SESSION_TOKEN'].blank?

      validate_required_vars!(required_vars, error_prefix: 'AWS Lambda Config Error')
    end

    # Validates required configuration for AWS AOSS connections.
    #
    # AWS_ROLE_ARN becomes required only when AWS_SESSION_TOKEN is not present.
    # This supports both temporary session-token auth and role-assumption auth.
    #
    # @return [nil]
    # @raise [RuntimeError] when required env vars are missing.
    def validate_aws_aoss_config
      required_vars = {
        'OPENSEARCH_URL' => ENV.fetch('OPENSEARCH_URL', nil),
        'AWS_ACCESS_KEY_ID' => ENV.fetch('AWS_ACCESS_KEY_ID', nil),
        'AWS_SECRET_ACCESS_KEY' => ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
      }

      # Required only when AWS_SESSION_TOKEN is not present (using role assumption)
      required_vars['AWS_ROLE_ARN'] = ENV.fetch('AWS_ROLE_ARN', nil) if ENV['AWS_SESSION_TOKEN'].blank?

      validate_required_vars!(required_vars, error_prefix: 'AWS AOSS Config Error')
    end

    # Validates required configuration for AWS-managed OpenSearch.
    #
    # @return [nil]
    # @raise [RuntimeError] when required env vars are missing.
    def validate_aws_os_config
      validate_required_vars!({
                                'OPENSEARCH_URL' => ENV.fetch('OPENSEARCH_URL', nil),
                                'AWS_ACCESS_KEY_ID' => ENV.fetch('AWS_ACCESS_KEY_ID', nil),
                                'AWS_SECRET_ACCESS_KEY' => ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
                              }, error_prefix: 'AWS OpenSearch Config Error')
    end

    private

    # Raises a standardized configuration error for missing env vars.
    #
    # @param required_vars [Hash{String => Object}] Mapping of env var names
    #   to their current values.
    # @param error_prefix [String] Prefix used to identify the validator path.
    # @return [nil]
    # @raise [RuntimeError] when one or more values are blank.
    def validate_required_vars!(required_vars, error_prefix:)
      missing_vars = required_vars.select { |_key, value| value.blank? }.keys

      return unless missing_vars.any?

      raise "#{error_prefix}: These required environment variables are not set: #{missing_vars.join(', ')}"
    end
  end
end
