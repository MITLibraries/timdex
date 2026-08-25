require 'test_helper'

class LambdaConfigTest < ActiveSupport::TestCase
  test 'configure_lambda_client uses assume role credentials when AWS_ROLE_ARN is set and no session token is present' do
    captured_options = nil

    ClimateControl.modify(
      AWS_REGION: 'us-east-1',
      AWS_ROLE_ARN: 'arn:aws:iam::123456789:role/MyLambdaRole',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
      AWS_SESSION_TOKEN: nil,
      AWS_ENDPOINT_URL_LAMBDA: 'http://localhost:9200'
    ) do
      Aws::STS::Client.stubs(:new).returns(:sts_client)
      Aws::AssumeRoleCredentials.stubs(:new).returns(:assume_role_credentials)
      Aws::Lambda::Client.stubs(:new).with do |opts|
        captured_options = opts
        true
      end.returns(:lambda_client)

      configure_lambda_client

      assert_equal 'us-east-1', captured_options[:region]
      assert_equal :assume_role_credentials, captured_options[:credentials]
      assert_equal 'http://localhost:9200', captured_options[:endpoint]

      Aws::AssumeRoleCredentials.expects(:new).with(
        has_entries(
          role_arn: 'arn:aws:iam::123456789:role/MyLambdaRole',
          role_session_name: 'timdex-lambda',
          client: :sts_client
        )
      )
      lambda_credentials
    end
  end

  test 'configure_lambda_client uses session token credentials when both AWS_SESSION_TOKEN and AWS_ROLE_ARN are set' do
    captured_options = nil

    ClimateControl.modify(
      AWS_REGION: 'us-east-1',
      AWS_ROLE_ARN: 'arn:aws:iam::123456789:role/MyLambdaRole',
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
      AWS_SESSION_TOKEN: 'FwoGZXIvYXdzEBEaDKB...',
      AWS_ENDPOINT_URL_LAMBDA: nil
    ) do
      Aws::AssumeRoleCredentials.expects(:new).never
      Aws::Lambda::Client.stubs(:new).with do |opts|
        captured_options = opts
        true
      end.returns(:lambda_client)

      configure_lambda_client

      assert_equal 'us-east-1', captured_options[:region]
      assert_kind_of Aws::Credentials, captured_options[:credentials]
      assert_nil captured_options[:endpoint]
      assert_equal 'FwoGZXIvYXdzEBEaDKB...', captured_options[:credentials].session_token
    end
  end

  test 'configure_lambda_client uses static credentials when access keys are present and no role ARN' do
    captured_options = nil

    ClimateControl.modify(
      AWS_REGION: 'us-east-1',
      AWS_ROLE_ARN: nil,
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
      AWS_SESSION_TOKEN: 'FwoGZXIvYXdzEBEaDKB...',
      AWS_ENDPOINT_URL_LAMBDA: nil
    ) do
      Aws::Lambda::Client.stubs(:new).with do |opts|
        captured_options = opts
        true
      end.returns(:lambda_client)

      configure_lambda_client

      assert_equal 'us-east-1', captured_options[:region]
      assert_kind_of Aws::Credentials, captured_options[:credentials]
      assert_nil captured_options[:endpoint]
    end
  end

  test 'configure_lambda_client raises error when required env vars are missing' do
    ClimateControl.modify(
      AWS_REGION: nil,
      AWS_ROLE_ARN: nil,
      AWS_ACCESS_KEY_ID: nil,
      AWS_SECRET_ACCESS_KEY: nil,
      AWS_SESSION_TOKEN: nil,
      AWS_ENDPOINT_URL_LAMBDA: nil
    ) do
      error = assert_raises(RuntimeError) do
        configure_lambda_client
      end

      assert_match(/AWS Lambda Config Error/, error.message)
      assert_match(/AWS_ACCESS_KEY_ID/, error.message)
      assert_match(/AWS_SECRET_ACCESS_KEY/, error.message)
    end
  end

  test 'configure_lambda_client raises error when AWS_ROLE_ARN is missing and AWS_SESSION_TOKEN is not present' do
    ClimateControl.modify(
      AWS_REGION: 'us-east-1',
      AWS_ROLE_ARN: nil,
      AWS_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
      AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
      AWS_SESSION_TOKEN: nil,
      AWS_ENDPOINT_URL_LAMBDA: nil
    ) do
      error = assert_raises(RuntimeError) do
        configure_lambda_client
      end

      assert_match(/AWS Lambda Config Error/, error.message)
      assert_match(/AWS_ROLE_ARN/, error.message)
    end
  end
end
