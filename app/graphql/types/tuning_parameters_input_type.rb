module Types
  class TuningParametersInputType < Types::BaseInputObject
    description 'Experimental tuning parameters for semantic search. Not recommended for use.'

    argument :must_boost_threshold, Float, required: false, default_value: nil,
                                           description: 'Not recommended for use. Range: 0.0 to 1.0'
    argument :drop_boost_threshold, Float, required: false, default_value: nil,
                                           description: 'Not recommended for use. Range: 0.0 to 1.0'
    argument :short_query_max_tokens, Integer, required: false, default_value: nil,
                                               description: 'Not recommended for use. Must be greater than 0'
  end
end
