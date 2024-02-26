# flipflip features are available to use in initializers so we cheat a bit here.
return unless ENV.fetch('PROMETHEUS', false).present?

require 'prometheus/client'
require 'prometheus/client/push'

prometheus = Prometheus::Client.registry
Timdex::GraphqlQueriesTotal = prometheus.counter(:graphql_queries_total, docstring: 'A counter of GraphQL requests made')

Timdex::GraphqlFieldUsage = prometheus.counter(:graphql_field_usage, docstring: 'A counter of GraphQL fields requested', labels: [:service, :field], preset_labels: { service: "timdex-api" })

Timdex::GraphqlDeprecatedFieldUsage = prometheus.counter(:graphql_deprecated_field_usage, docstring: 'A counter of deprecated GraphQL fields requested', labels: [:service, :field], preset_labels: { service: "timdex-api" })

Timdex::GraphqlDeprecatedArguments = prometheus.counter(:graphql_deprecated_argument_usage, docstring: 'A counter of deprecated GraphQL arguments requested', labels: [:service, :field], preset_labels: { service: "timdex-api" })
