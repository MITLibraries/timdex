Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :session
  strategy :default

  feature :geospatial_search,
    default: ActiveModel::Type::Boolean.new.cast(ENV.fetch('GEOSPATIAL_SEARCH', false)),
    description: 'Includes geospatial search capabilities'
end
