Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :session
  strategy :default

 feature :prometheus,
    default: ENV.fetch('PROMETHEUS', false),
    description: "Enable prometheus metrics endpoint"
end
