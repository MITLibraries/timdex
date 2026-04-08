require 'test_helper'
require 'opensearch_config_validator'

class OpensearchConfigTest < ActiveSupport::TestCase
  # AWS AOSS validation tests
  test 'validate_aws_aoss_config raises error when required vars are missing' do
    ClimateControl.modify(
      AWS_AOSS: 'true',
      OPENSEARCH_URL: nil,
      AWS_REGION: nil,
      AWS_AOSS_ROLE_ARN: nil,
      AWS_ACCESS_KEY_ID: nil,
      AWS_SECRET_ACCESS_KEY: nil
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_aoss_config
      end

      assert_match(/AWS AOSS Config Error/, error.message)
      assert_match(/OPENSEARCH_URL/, error.message)
      assert_match(/AWS_REGION/, error.message)
      assert_match(/AWS_ACCESS_KEY_ID/, error.message)
      assert_match(/AWS_SECRET_ACCESS_KEY/, error.message)
    end
  end

  test 'validate_aws_aoss_config raises error when OPENSEARCH_URL is missing' do
    ClimateControl.modify(
      OPENSEARCH_URL: nil,
      AWS_REGION: 'us-east-1',
      AWS_AOSS_ROLE_ARN: 'arn:aws:iam::123456789:role/MyRole',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_aoss_config
      end

      assert_match(/OPENSEARCH_URL/, error.message)
    end
  end

  test 'validate_aws_aoss_config raises error when AWS_REGION is missing' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.aoss.amazonaws.com',
      AWS_REGION: nil,
      AWS_AOSS_ROLE_ARN: 'arn:aws:iam::123456789:role/MyRole',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_aoss_config
      end

      assert_match(/AWS_REGION/, error.message)
    end
  end

  test 'validate_aws_aoss_config raises error when AWS_ACCESS_KEY_ID is missing' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.aoss.amazonaws.com',
      AWS_REGION: 'us-east-1',
      AWS_AOSS_ROLE_ARN: 'arn:aws:iam::123456789:role/MyRole',
      AWS_ACCESS_KEY_ID: nil,
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_aoss_config
      end

      assert_match(/AWS_ACCESS_KEY_ID/, error.message)
    end
  end

  test 'validate_aws_aoss_config raises error when AWS_SECRET_ACCESS_KEY is missing' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.aoss.amazonaws.com',
      AWS_REGION: 'us-east-1',
      AWS_AOSS_ROLE_ARN: 'arn:aws:iam::123456789:role/MyRole',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: nil
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_aoss_config
      end

      assert_match(/AWS_SECRET_ACCESS_KEY/, error.message)
    end
  end

  test 'validate_aws_aoss_config requires AWS_AOSS_ROLE_ARN when AWS_SESSION_TOKEN is not present' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.aoss.amazonaws.com',
      AWS_REGION: 'us-east-1',
      AWS_AOSS_ROLE_ARN: nil,
      AWS_SESSION_TOKEN: nil,
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_aoss_config
      end

      assert_match(/AWS_AOSS_ROLE_ARN/, error.message)
    end
  end

  test 'validate_aws_aoss_config does not require AWS_AOSS_ROLE_ARN when AWS_SESSION_TOKEN is present' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.aoss.amazonaws.com',
      AWS_REGION: 'us-east-1',
      AWS_AOSS_ROLE_ARN: nil,
      AWS_SESSION_TOKEN: 'FwoGZXIvYXdzEBEaDKB...',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      assert_nil OpensearchConfigValidator.validate_aws_aoss_config
    end
  end

  test 'validate_aws_aoss_config succeeds with all required values present' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.aoss.amazonaws.com',
      AWS_REGION: 'us-east-1',
      AWS_AOSS_ROLE_ARN: 'arn:aws:iam::123456789:role/MyRole',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      assert_nil OpensearchConfigValidator.validate_aws_aoss_config
    end
  end

  # AWS OpenSearch validation tests
  test 'validate_aws_os_config raises error when required vars are missing' do
    ClimateControl.modify(
      AWS_OPENSEARCH: 'true',
      OPENSEARCH_URL: nil,
      AWS_REGION: nil,
      AWS_ACCESS_KEY_ID: nil,
      AWS_SECRET_ACCESS_KEY: nil
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_os_config
      end

      assert_match(/AWS OpenSearch Config Error/, error.message)
      assert_match(/OPENSEARCH_URL/, error.message)
      assert_match(/AWS_REGION/, error.message)
      assert_match(/AWS_ACCESS_KEY_ID/, error.message)
      assert_match(/AWS_SECRET_ACCESS_KEY/, error.message)
    end
  end

  test 'validate_aws_os_config raises error when OPENSEARCH_URL is missing' do
    ClimateControl.modify(
      OPENSEARCH_URL: nil,
      AWS_REGION: 'us-east-1',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_os_config
      end

      assert_match(/OPENSEARCH_URL/, error.message)
    end
  end

  test 'validate_aws_os_config raises error when AWS_REGION is missing' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.es.amazonaws.com',
      AWS_REGION: nil,
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_os_config
      end

      assert_match(/AWS_REGION/, error.message)
    end
  end

  test 'validate_aws_os_config raises error when AWS_ACCESS_KEY_ID is missing' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.es.amazonaws.com',
      AWS_REGION: 'us-east-1',
      AWS_ACCESS_KEY_ID: nil,
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_os_config
      end

      assert_match(/AWS_ACCESS_KEY_ID/, error.message)
    end
  end

  test 'validate_aws_os_config raises error when AWS_SECRET_ACCESS_KEY is missing' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.es.amazonaws.com',
      AWS_REGION: 'us-east-1',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: nil
    ) do
      error = assert_raises(RuntimeError) do
        OpensearchConfigValidator.validate_aws_os_config
      end

      assert_match(/AWS_SECRET_ACCESS_KEY/, error.message)
    end
  end

  test 'validate_aws_os_config succeeds with all required values present' do
    ClimateControl.modify(
      OPENSEARCH_URL: 'https://example.us-east-1.es.amazonaws.com',
      AWS_REGION: 'us-east-1',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    ) do
      assert_nil OpensearchConfigValidator.validate_aws_os_config
    end
  end
end
