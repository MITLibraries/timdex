Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :session
  strategy :default

  feature :v2,
    default: ENV.fetch('V2', false),
    description: "TIMDEX v2 spec is enabled. All of GraphQL will use OpenSearch. GraphQL Schema deprecates fields when possible"
end
