[![Maintainability](https://api.codeclimate.com/v1/badges/5af08033c5f1257a1fd1/maintainability)](https://codeclimate.com/github/MITLibraries/timdex/maintainability)

# TIMDEX Is Making Discovery EXcellent @ MIT

This application interfaces with an OpenSearch backend and exposes a GraphQL endpoint to allow anonymous users to query our data.

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

Once the jekyll server is running, you can access the local docs at http://localhost:4000

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

## Required Environment Variables (all ENVs)

- `EMAIL_FROM`: email address to send message from, including the registration
  and forgot password messages.
- `EMAIL_URL_HOST` - base url to use when sending emails that link back to the
  application. In development, often `localhost:3000`. On heroku, often
  `yourapp.herokuapp.com`. However, if you use a custom domain in production,
  that should be the value you use in production.
- `JWT_SECRET_KEY`: generate with `rails secret`

## Production required Environment Variables

- `AWS_OPENSEARCH`: boolean. Set to true to enable AWSv4 Signing
- `AWS_OPENSEARCH_ACCESS_KEY_ID`
- `AWS_OPENSEARCH_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `OPENSEARCH_INDEX`: Opensearch index or alias to query, default will be to search all indexes which is generally not
                      expected. `timdex` or `all-current` are aliases used consistently in our data pipelines, with
                      `timdex` being most likely what most use cases will want.
- `OPENSEARCH_URL`: Opensearch URL, defaults to `http://localhost:9200`
- `SMTP_ADDRESS`
- `SMTP_PASSWORD`
- `SMTP_PORT`
- `SMTP_USER`

## Optional Environment Variables (all ENVs)

- `OPENSEARCH_LOG` if `true`, verbosely logs OpenSearch queries.

  ```text
  NOTE: do not set this ENV at all if you want ES logging fully disabled.
  Setting it to `false` is still setting it and you will be annoyed and
  confused.
  ```

- `PREFERRED_DOMAIN` - set this to the domain you would like to to use. Any
  other requests that come to the app will redirect to the root of this domain.
  This is useful to prevent access to herokuapp.com domains.
- `REQUESTS_PER_PERIOD` - requests allowed before throttling. Default is 100.
- `REQUEST_PERIOD` - number of minutes for the period in `REQUESTS_PER_PERIOD`.
  Default is 1.
- `SENTRY_DSN`: client key for Sentry exception logging
- `SENTRY_ENV`: Sentry environment for the application. Defaults to 'unknown' if unset.
