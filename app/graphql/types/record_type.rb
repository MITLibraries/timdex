module Types
  class RecordType < BaseObject
    field :identifier, ID, null: false
    field :source, String, null: false
    field :source_link, String, null: false
    field :title, String, null: false
    field :alternate_titles, [String], null: true
    # Contributor          []*Contributor `json:"contributors,omitempty"`
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
  	# RelatedItems         []*RelatedItem `json:"related_items,omitempty"`
  	# Links                []Link         `json:"links,omitempty"`
  	# Holdings             []Holding      `json:"holdings,omitempty"`

  end
end
