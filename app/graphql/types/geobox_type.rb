module Types
  class GeoboxType < Types::BaseInputObject
    description 'Search within a box specified by pairs of latitudes and longitudes. Their order should be left, ' \
                'bottom, right, top'
    argument :min_longitude, Float, description: 'A decimal between -180.0 and 180.0 (Western hemisphere is negative)'
    argument :min_latitude, Float, description: 'A decimal between -90.0 and 90.0 (Southern hemisphere is negative)'
    argument :max_longitude, Float, description: 'A decimal between -180.0 and 180.0 (Western hemisphere is negative)'
    argument :max_latitude, Float, description: 'A decimal between -90.0 and 90.0 (Southern hemisphere is negative)'
  end
end
