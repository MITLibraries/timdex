module Types
  class RecordType < BaseObject
    field :identifier, ID, null: false
    field :title, String, null: false
  end
end
