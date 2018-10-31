# TIMDEX Is Making Discovery EXcellent @ MIT

This application interfaces with an ElasticSearch backend and exposes a set of
API Endpoints to allow registered users to query our data.

The backend is populated via [pipelines](https://github.com/MITLibraries/mario).

# Architecture Decision Records

This repository contains Architecture Decision Records in the
[docs/architecture-decisions directory](docs/architecture_decisions).

[adr-tools](https://github.com/npryce/adr-tools) should allow easy creation of
additional records with a standardized template.

# Developing this application

- please `bundle exec annotate` when making changes to models to update the
  internal documentation
- don't commit your .env or .env.development, but do commit .env.test after
  confirming your test values are not actual secrets that need protecting

# Required Environment Variables (all ENVs)

- `EMAIL_FROM`:  email address to send message from, including the registration
  and forgot password messages.
- `EMAIL_URL_HOST` - base url to use when sending emails that link back to the
  application. In development, often `localhost:3000`. On heroku, often
  `yourapp.herokuapp.com`. However, if you use a custom domain in production,
  that should be the value you use in production.
- `JWT_SECRET_KEY`: generate with `rails secret`
- `ELASTICSEARCH_URL`: defaults to `http://localhost:9200`

# Production required Environment Variables
- `AWS_ACCESS_KEY`
- `AWS_ELASTICSEARCH`: boolean. Set to true to enable AWSv4 Signing
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `SMTP_ADDRESS`
- `SMTP_PASSWORD`
- `SMTP_PORT`
- `SMTP_USER`

# Optional Environment Variables (all ENVs)
- `ELASTICSEARCH_LOG` if `true`, verbosely logs ElasticSearch queries
