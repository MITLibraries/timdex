[![Maintainability](https://api.codeclimate.com/v1/badges/5af08033c5f1257a1fd1/maintainability)](https://codeclimate.com/github/MITLibraries/timdex/maintainability)

# TIMDEX Is Making Discovery EXcellent @ MIT

This application interfaces with an ElasticSearch backend and exposes a set of
API Endpoints to allow registered users to query our data.

The backend is populated via [pipelines](https://github.com/MITLibraries/mario).

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

### Updating the data model
Updating the data model is somewhat complicated because many files need to be
edited across multiple repositories and deployment steps should happen in a
particular order so as not to break production services.
- Start by updating the data model in [Mario](https://github.com/MITLibraries/mario). Instructions for that can be found
  in the [Mario README](https://github.com/MITLibraries/mario/blob/master/README.md). Then complete the following steps here in TIMDEX.
- Update `app/models/search.rb` to build/update/remove queries for the added/
  edited/deleted fields as appropriate. Make sure to update filters and
  aggregations if relevant to the changed fields.
- Update `app/views/api/[version]/search/_base_json_jbuilder` to
  add/update/remove changed fields OR update
  `views/api/[version]/search/_extended_json_jbuilder` if the changed fields
  aren’t/shouldn’t be in the brief record result.
- If changed fields should be aggregated, update
  `views/api/[version]/search/_aggregations_json_jbuilder` as appropriate.
- Update tests as necessary. Make sure to test with all current data
  source samples ingested into a local ES instance.
- Update `openapi.json` to make sure our spec matches any changes made
  (including bumping the version number).

## Publishing User Facing Documentation

### Running jekyll documentation locally

Documentation is built and deployed via Github Actions. You can run the documentation locally before pushing to Github
to ensure everything looks as expected.

```shell
bundle exec jekyll serve --incremental --source ./docs
```

Once the jekyll server is running, you can access the local docs at http://localhost:4000

### Automatic generation from openapi specification

We are using Swagger UI to automatically generate documentation from the `openapi.json` file in GitHub Pages. The HTML
file is in `docs/index.html` and the `openapi.json` file always pulls from the `main` branch.
## Required Environment Variables (all ENVs)

- `EMAIL_FROM`: email address to send message from, including the registration
  and forgot password messages.
- `EMAIL_URL_HOST` - base url to use when sending emails that link back to the
  application. In development, often `localhost:3000`. On heroku, often
  `yourapp.herokuapp.com`. However, if you use a custom domain in production,
  that should be the value you use in production.
- `JWT_SECRET_KEY`: generate with `rails secret`
- `ELASTICSEARCH_INDEX`: Elasticsearch index or alias to query
- `ELASTICSEARCH_URL`: defaults to `http://localhost:9200`

## Production required Environment Variables

- `AWS_ACCESS_KEY`
- `AWS_ELASTICSEARCH`: boolean. Set to true to enable AWSv4 Signing
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `SMTP_ADDRESS`
- `SMTP_PASSWORD`
- `SMTP_PORT`
- `SMTP_USER`

### Additional required Environment Variables when Opensearch is enabled (aka v2=true)

- `v2`: set to `true`
- `OPENSEARCH_INDEX`: Opensearch index or alias to query
- `OPENSEARCH_URL`: Opensearch URL
- `OPENSEARCH_LOG` set to `true`

- `AWS_OPENSEARCH`
- `AWS_OPENSEARCH_ACCESS_KEY_ID`
- `AWS_OPENSEARCH_SECRET_ACCESS_KEY`
## Optional Environment Variables (all ENVs)

- `ELASTICSEARCH_LOG` if `true`, verbosely logs ElasticSearch queries.

  ```text
  NOTE: do not set this ENV at all if you want ES logging fully disabled.
  Setting it to `false` is still setting it and you will be annoyed and
  confused.
  ```

- `ES_LOG_LEVEL` set elasticsearch transport log level. Defaults to `INFO`.

```text
NOTE: `ELASTICSEARCH_LOG` must also be set for logging to function.
```

- `PREFERRED_DOMAIN` - set this to the domain you would like to to use. Any
  other requests that come to the app will redirect to the root of this domain.
  This is useful to prevent access to herokuapp.com domains.
- `REQUESTS_PER_PERIOD` - requests allowed before throttling. Default is 100.
- `REQUEST_PERIOD` - number of minutes for the period in `REQUESTS_PER_PERIOD`.
  Default is 1.
- `SENTRY_DSN`: client key for Sentry exception logging
- `SENTRY_ENV`: Sentry environment for the application. Defaults to 'unknown' if unset.

## Docker Compose Orchestrated Local Environment

This section will describe how to use the included docker compose files to spin up ElasticSearch
and optionally use Mario to load sample data for testing.

You may set `ELASTICSEARCH_URL` to `http://0.0.0.0:9200` to use this ES instance in development if you
choose to not use the included Dockerfile

### Startup ElasticSearch and Timdex

`make up`

### Shutdown ElasticSearch and Timdex when you are done

`make down`

### Optionally, load sample data

After ElasticSearch is running from `make up` command:

`make sampledata`

Note: if you run this and it fails, try again in a few seconds as ES may still be loading

### Run arbitrary Mario commands

You can also run arbitrary Mario commands using a syntax like this after first running `make up`.

`docker run --network timdex_default mitlibraries/mario --url http://elasticsearch:9200 YOUR_MARIO_COMMAND_HERE [e.g. indexes]`

Note: if you have no indexes loaded, many mario commands will fail. Try `make sampledata` or load the data you
need before proceeding.

### Quick curl examples with sample data in mind

`curl 'http://0.0.0.0:3000/api/v1/ping'`

`curl 'http://0.0.0.0:3000/api/v1/search?q=archives'`

You can also use the playground via your browser, see the index page of the running app for a link
and example queries.

http://0.0.0.0:3000
