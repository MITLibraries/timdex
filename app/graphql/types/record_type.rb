module Types
  class LinkType < BaseObject
    field :kind, String, null: true
    field :text, String, null: true
    field :url, String, null: false
    field :restrictions, String, null: true
  end

  class ContributorType < BaseObject
    field :kind, String, null: true
    field :value, String, null: false
  end

  class HoldingType < BaseObject
    field :location, String, null: false
    field :collection, String, null: true
    field :callnumber, String, null: true
    field :summary, String, null: true
    field :notes, String, null: true
    field :format, String, null: true
  end

  class RelatedItemType < BaseObject
    field :kind, String, null: true
    field :value, [String], null: false
  end

  class RecordType < BaseObject
    field :identifier, ID, null: false
    field :source, String, null: false
    field :source_link, String, null: false
    field :title, String, null: false
    field :alternate_titles, [String], null: true
    field :contributors, [Types::ContributorType], null: true
    field :subjects, [String], null: true
    field :isbns, [String], null: true
    field :issns, [String], null: true
    field :dois, [String], null: true
    field :oclcs, [String], null: true
    field :lccn, String, null: true
    field :place_of_publication, String, null: true
    field :languages, [String], null: true
    field :publication_date, String, null: true
    field :content_type, String, null: true
    field :call_numbers, [String], null: true
    field :edition, String, null: true
    field :imprint, [String], null: true
    field :physical_description, String, null: true
    field :publication_frequency, [String], null: true
    field :numbering, String, null: true
    field :notes, [String], null: true
    field :contents, [String], null: true
    field :summary, [String], null: true
    field :format, [String], null: true
    field :literary_form, String, null: true
    field :related_place, String, null: true
    field :in_bibliography, [String], null: true
    field :related_items, [Types::RelatedItemType], null: true
    field :links, [Types::LinkType], null: true
    field :holdings, [Types::HoldingType], null: true
  end
end
