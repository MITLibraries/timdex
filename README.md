# TIMDEX Is Making Discovery EXcellent @ MIT

This application interfaces with an ElasticSearch backend and exposes a set of
API Endpoints to allow registered users to query our data.

The backend is populated via [pipelines](https://github.com/MITLibraries/mario).

## Architecture Decision Records

This repository contains Architecture Decision Records in the
[docs/architecture-decisions directory](docs/architecture_decisions).

[adr-tools](https://github.com/npryce/adr-tools) should allow easy creation of
additional records with a standardized template.

## Developing this application

- please `bundle exec annotate` when making changes to models to update the
  internal documentation
- don't commit your .env or .env.development, but do commit .env.test after
  confirming your test values are not actual secrets that need protecting

## Publishing User Facing Documentation

### Automatic generation from openapi specification
- Sign into stoplight.io with an account that has access to the MIT Libraries organization
- copy the source of `openapi.json` file from this repository to the code tab in our [stoplight model](https://next.stoplight.io/mit-libraries/timdex/version%2F1.0/openapi.oas3.yml)
- In [Stoplight's Publish](https://next.stoplight.io/mit-libraries/timdex/version%2F1.0/timdex.hub.yml?view=/&show=publish&domain=mitlibraries-timdex.docs.stoplight.io) section, Uncheck "set live" and then click "Build"
- Once docs are built, check they are sane with the preview feature then click "set live"

## Required Environment Variables (all ENVs)

- `EMAIL_FROM`:  email address to send message from, including the registration
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

## Optional Environment Variables (all ENVs)
- `ELASTICSEARCH_LOG` if `true`, verbosely logs ElasticSearch queries
- `PREFERRED_DOMAIN` - set this to the domain you would like to to use. Any
  other requests that come to the app will redirect to the root of this domain.
  This is useful to prevent access to herokuapp.com domains.
- `REQUESTS_PER_PERIOD` - requests allowed before throttling. Default is 100.
- `REQUEST_PERIOD` - number of minutes for the period in `REQUESTS_PER_PERIOD`.
  Default is 1.

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

`docker run --network timdex_default mitlibraries/mario:aspace --url http://elasticsearch:9200 YOUR_MARIO_COMMAND_HERE`

Note: if you have no indexes loaded, many mario commands will fail. Try `make sampledata` or load the data you
need before proceeding.

### Quick curl examples with sample data in mind

`curl 'http://0.0.0.0:3000/api/v1/ping'`

`curl 'http://0.0.0.0:3000/api/v1/search?q=archives'`

You can also use the playground via your browser, see the index page of the running app for a link
and example queries.

http://0.0.0.0:3000
