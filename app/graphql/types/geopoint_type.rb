module Types
  class GeopointType < Types::BaseInputObject
    argument :longitude, String
    argument :latitude, String
  end
end
