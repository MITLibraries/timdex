module Types
  class GeodistanceType < Types::BaseInputObject
    description 'Search within a certain distance of a given latitude and longitude'
    argument :distance, String, description: 'Search distance to the location? (include units; i.e. "100km" or "50mi")'
    argument :latitude, Float, description: 'A decimal between -90.0 and 90.0 (Southern hemisphere is negative)'
    argument :longitude, Float, description: 'A decimal between -180.0 and 180.0 (Western hemisphere is negative)'
  end
end
