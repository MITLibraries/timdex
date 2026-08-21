require 'aws_auth'

# AwsConfigValidator validates AWS-related environment configuration for
# OpenSearch and Lambda initialization.
class AwsConfigValidator
  class << self
    def validate_lambda_config
      AwsAuth.validate_base_aws_config!(error_prefix: 'AWS Lambda Config Error')
    end

    def validate_aws_aoss_config
      required_vars = {
        'OPENSEARCH_URL' => ENV.fetch('OPENSEARCH_URL', nil),
        'AWS_REGION' => ENV.fetch('AWS_REGION', nil),
        'AWS_ACCESS_KEY_ID' => ENV.fetch('AWS_ACCESS_KEY_ID', nil),
        'AWS_SECRET_ACCESS_KEY' => ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
      }

      # Required only when AWS_SESSION_TOKEN is not present (using role assumption)
      required_vars['AWS_ROLE_ARN'] = ENV.fetch('AWS_ROLE_ARN', nil) if ENV['AWS_SESSION_TOKEN'].blank?

      AwsAuth.validate_required_vars!(required_vars, error_prefix: 'AWS AOSS Config Error')
    end

    def validate_aws_os_config
      AwsAuth.validate_required_vars!({
                                        'OPENSEARCH_URL' => ENV.fetch('OPENSEARCH_URL', nil),
                                        'AWS_REGION' => ENV.fetch('AWS_REGION', nil),
                                        'AWS_ACCESS_KEY_ID' => ENV.fetch('AWS_ACCESS_KEY_ID', nil),
                                        'AWS_SECRET_ACCESS_KEY' => ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
                                      }, error_prefix: 'AWS OpenSearch Config Error')
    end
  end
end
