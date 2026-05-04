[![Maintainability](https://api.codeclimate.com/v1/badges/5af08033c5f1257a1fd1/maintainability)](https://codeclimate.com/github/MITLibraries/timdex/maintainability)

# TIMDEX Is Making Discovery EXcellent @ MIT

This application interfaces with an OpenSearch backend and exposes a GraphQL endpoint to allow anonymous users to query our data.

- [Architecture Decision Records](#architecture-decision-records)
- [Developing this application](#developing-this-application)
- [Generating cassettes for tests](#generating-cassettes-for-tests)
- [Confirming functionality after updating dependencies](#confirming-functionality-after-updating-dependencies)
- [Publishing User Facing Documentation](#publishing-user-facing-documentation)
  - [Running jekyll documentation locally](#running-jekyll-documentation-locally)
  - [Automatic generation of technical specifications from GraphQL](#automatic-generation-of-technical-specifications-from-graphql)
- [General Configuration](#general-configuration)
  - [Name and Domain](#name-and-domain)
  - [Authentication](#authentication)
  - [Email Configuration](#email-configuration)
  - [Observability (Optional)](#observability-optional)
  - [Rate Limiting (Optional)](#rate-limiting-optional)
- [AWS Configuration](#aws-configuration)
  - [OpenSearch Configuration](#opensearch-configuration)
  - [AWS Credentials (Used for AWS-based OpenSearch and timdex-semantic-builder)](#aws-credentials-used-for-aws-based-opensearch-and-timdex-semantic-builder)
  - [AWS OpenSearch Service (Legacy)](#aws-opensearch-service-legacy)
  - [AWS OpenSearch Serverless (AOSS)](#aws-opensearch-serverless-aoss)
  - [TIMDEX Semantic Builder Lambda](#timdex-semantic-builder-lambda)

## Architecture Decision Records

This repository contains Architecture Decision Records in the
[docs/architecture-decisions directory](docs/architecture-decisions).

[adr-tools](https://github.com/npryce/adr-tools) should allow easy creation of
additional records with a standardized template.

## Developing this application

- please `bundle exec annotate` when making changes to models to update the
  internal documentation
- don't commit your .env or .env.development, but do commit .env.test after
  confirming your test values are not actual secrets that need protecting

## Generating cassettes for tests

We use [VCR](https://github.com/vcr/vcr) to record transactions with OpenSearch so we will not need to load
data for testing during each test run.

We must take care to not record our credentials to any secure OpenSearch clusters we use _and_ we must make sure all cassettes look like the same
endpoint.

One option would be to force us to load data locally and only generate cassettes from localhost OpenSearch. This is secure, but is not always convenient to ensure we have test data that looks like production.

The other option is to use deployed OpenSearch and scrub the data using VCRs [filter_sensitive_data](https://benoittgt.github.io/vcr/#/configuration/filter_sensitive_data) feature.

The scrubbing has been configured in `test/test_helper.rb`.

The test recording process is as follows:

- If you want to use localhost:9200
  - load the data you want and ensure it is accessible via the `all-current` alias. No other changes are necessary
- If you want to use an AWS OpenSearch instance

> [!CAUTION]
> Use `.env` and _not_ `.env.test` to override these values to ensure you do not inadvertantly commit secrets!

- Set the following values to whatever cluster you want to connect to in `.env` (Note: `.env` is preferred over `.env.test` because it is already in our `.gitignore` and will work together with `.env.test`.)
  - OPENSEARCH_URL
  - AWS_OPENSEARCH=true
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - AWS_REGION
- Delete any cassette you want to regenerate (for new tests, you can skip this). If you are making a graphql test, nest your cassette inside the `opensearch_init` cassette.

Example of nested cassettes.

```ruby
test 'graphql search' do
  VCR.use_cassette('opensearch init') do
    VCR.use_cassette('YOUR CASSETTE NAME') do
      YOUR QUERY
      YOUR ASSERTIONS
    end
  end
end
```

- Run your test(s). You may receive VCR errors as the `opensearch init` cassette does not have the HTTP transaction you are requesting. However, the nested cassette for your test will generate if it does not exist yet and on future runs these errors will not recur.
- Manually confirm the headers do not have sensitive information. This scrubbing process should work, but it is your responsibility to ensure you are not committing secrets to code repositories. If you aren't sure, ask.
- You have to remove or comment out AWS credentials from `.env` before re-running your test or the tests will fail (i.e. this process can only generate cassettes, it can not re-run them with AWS credentials as we scrub the AWS bits from the cassette so VCR does not match).
- You have to set `AWS_ENDPOINT_URL_LAMBDA` to `http://localhost:9200` in `.env.test` before re-running tests. This is necessary because the initial call uses the default value set by the AWS SDK but subsequent calls use the filtered value.

> [!Important]
> We re-use OpenSearch connections, which is handled by the nesting of cassettes (see above). If you have sporadically failing tests, ensure you are nesting your test specific cassette inside of the `opensearch init` cassette.

## Confirming functionality after updating dependencies

This application has good code coverage, so most issues are detected by just running tests normally:

```shell
bin/rails test
```

The following additional manual testing should be performed in the PR build on Heroku.

- Use the PR builds GraphiQL playground to run a keyword search such as:

```graphql
{
  search(searchterm: "thesis") {
    hits
    records {
      title
      source
      summary
      identifiers {
        kind
        value
      }
    }
  }
}
```

- Use the PR builds GraphiQL playground to retrieve a single record

```graphql
{
  recordId(id: "alma:990000959610106761") {
    title
    timdexRecordId
    source
  }
}
```

The following additional manual check should be performed after the application is deployed to production.

- confirm the [main documentation site](https://mitlibraries.github.io/timdex/) is working by loading one or two pages
- confirm the [technical documentation site](https://mitlibraries.github.io/timdex/reference/) is working by loading it

## Publishing User Facing Documentation

### Running jekyll documentation locally

Documentation is built and deployed via Github Actions. You can run the documentation locally before pushing to Github
to ensure everything looks as expected.

```shell
bundle exec jekyll serve --incremental --source ./docs
```

Once the jekyll server is running, you can access the local docs at <http://localhost:4000/timdex/>

Note: it is important to load the documentation from the `/timdex/` path locally as that is how it works when built and deployed to GitHub Pages so testing locally the same way will ensure our asset paths will work when deployed.

### Automatic generation of technical specifications from GraphQL

Our GitHub Actions documentation build includes a step that uses [SpectaQL](https://github.com/anvilco/spectaql) to
generate technical documentation from our GraphQL spec.

You can generate this locally by installing SpectaQL and generating the html. See `Install SpectaQL` and
`Build reference docs` in `./.github/workflows/pages.yml` for details on this process.

Note: These files are intentionally excluded from version control to ensure the output generated via the Actions step is
considered authoritative.

The config file `./docs/reference/_spectaql_config.yml` controls the build process for this portion of our documentation
and making changes to this file (which is included in version control) would be the main reason to run the process
locally.

## General Configuration

### Name and Domain

- `PLATFORM_NAME`: The value set is added to the header after the MIT Libraries logo. The logic and CSS for this comes from our theme gem.
- `PREFERRED_DOMAIN`: set this to the domain you would like to use. Any other requests that come to the app will redirect to the root of this domain. This is useful to prevent access to herokuapp.com domains.

### Authentication

- `JWT_SECRET_KEY`: generate with `rails secret` **required**

### Email Configuration

- `EMAIL_FROM`: email address to send message from, including the registration and forgot password messages. **required**
- `EMAIL_URL_HOST`: base url to use when sending emails that link back to the application. In development, often `localhost:3000`. On heroku, often `yourapp.herokuapp.com`. However, if you use a custom domain in production, that should be the value you use in production. **required**
- `SMTP_ADDRESS`: SMTP server address (Required for production)
- `SMTP_PORT`: SMTP server port (Required for production)
- `SMTP_USER`: SMTP authentication user (Required for production)
- `SMTP_PASSWORD`: SMTP authentication password (Required for production)

### Observability (Optional)

- `RAILS_LOG_LEVEL`: defaults to debug in development and info in production
- `SENTRY_DSN`: client key for Sentry exception logging
- `SENTRY_ENV`: Sentry environment for the application. Defaults to 'unknown' if unset.

### Rate Limiting (Optional)

- `REQUESTS_PER_PERIOD`: requests allowed before throttling. Default is 100.
- `REQUEST_PERIOD`: number of minutes for the period in `REQUESTS_PER_PERIOD`. Default is 1.

## AWS Configuration

### OpenSearch Configuration

- `OPENSEARCH_URL`: OpenSearch endpoint URL, defaults to `http://localhost:9200`
- `OPENSEARCH_INDEX`: OpenSearch index or alias to query. Defaults to searching all indexes (generally not recommended). `timdex` or `all-current` are aliases used consistently in our data pipelines, with `timdex` being most likely what most use cases will want. **required**
- `OPENSEARCH_LOG`: if set to `true` (case-insensitive), verbosely logs OpenSearch queries. Leave unset, or set to any other value such as `false`, to keep OpenSearch logging disabled.
- `OPENSEARCH_SOURCE_EXCLUDES`: comma-separated list of fields to exclude from the OpenSearch `_source` field. Leave unset to return all fields. Recommended value: `embedding_full_record,fulltext`

### AWS Credentials (Used for AWS-based OpenSearch and timdex-semantic-builder)

- `AWS_ACCESS_KEY_ID`: AWS access key for OpenSearch and Lambda
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for OpenSearch and Lambda
- `AWS_REGION`: AWS region for OpenSearch and Lambda services
- `AWS_SESSION_TOKEN`: (Optional) AWS session token for temporary credentials when using expiring AWS credentials.
  Use this with temporary AWS credentials for AWS-based OpenSearch access and Lambda.
  For AOSS, when this is set, temporary credentials are used directly and `AWS_AOSS_ROLE_ARN` is not needed.

### AWS OpenSearch Service (Legacy)

This is our legacy AWS OpenSearch Service Cluster. All production instances should use this until our migration to Serverless (AOSS) is complete.

- `AWS_OPENSEARCH`: boolean. Set to `true` to enable AWS SigV4 signing for AWS OpenSearch Service. This is the legacy approach and will be replaced with `AWS_AOSS` when we complete our migration to Serverless.

### AWS OpenSearch Serverless (AOSS)

This is our upcoming configuration once migration is complete. This uses a different [authentication mechanism](https://github.com/awsdocs/amazon-opensearch-service-developer-guide/blob/master/doc_source/serverless-clients.md#ruby) than our legacy AWS OpenSearch Service.

- `AWS_AOSS`: boolean. Set to `true` to enable AWS OpenSearch Serverless (AOSS).
- `AWS_AOSS_ROLE_ARN`: AWS IAM role ARN to assume for AOSS authentication. **Required when** `AWS_AOSS=true` **and** `AWS_SESSION_TOKEN` is not set. This enables automatic credential refresh via role assumption.
  When `AWS_SESSION_TOKEN` is present, temporary credentials are used directly and `AWS_AOSS_ROLE_ARN` is not needed. This is only used in local development. `AWS_AOSS_ROLE_ARN` is used in production.

### TIMDEX Semantic Builder Lambda

- `TIMDEX_SEMANTIC_BUILDER_FUNCTION_NAME`: AWS Lambda function name with alias for semantic query building.
  Configurable to use alternative deployment tiers (e.g., dev1, stage, prod). Generally takes the format `function_name:live` where `live` is the alias. Failure to include the alias will result in extremely slow performance at best. Use the alias. Note: the lambda must be in the same AWS account as OpenSearch. If you want to test dev1 OpenSearch, you must also switch the lambda name to a dev1 variant.
