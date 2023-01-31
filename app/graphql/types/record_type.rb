module Types
  class LinkType < Types::BaseObject
    field :kind, String, null: true, description: 'Type of link'
    field :text, String, null: true, description: 'Additional description of a link, if applicable'
    field :url, String, null: false, description: 'URL of a link'
    field :restrictions, String, null: true, description: 'Restrictions on a link, if available'
  end

  if Flipflop.v2?
    class ContributorType < Types::BaseObject
      field :kind, String, null: true, description: 'Type of contributor; e.g., editor, author, etc.'
      field :value, String, null: false, description: 'Name of contributor'
      field :identifier, [String], null: true, description: 'Unique identifier(s) of a contributor'
      field :affiliation, [String], null: true, description: 'Institutional affiliation(s) of a contributor'
      field :mit_affiliated, Boolean, null: true, description: 'Identifies whether a contributor is affiliated with MIT'
    end
  else
    class ContributorType < Types::BaseObject
      field :kind, String, null: true
      field :value, String, null: false
    end
  end

  class HoldingType < Types::BaseObject
    field :location, String, null: false, description: 'Physical location of the holding'
    field :collection, String, null: true, description: 'Collection in which the item is held'
    field :callnumber, String, null: true, description: 'Call number of the holding'
    field :summary, String, null: true, description: 'Summary holdings information'
    field :notes, String, null: true, description: 'Cataloging notes about the holding'
    field :format, String, null: true, description: 'Format of the holding'
  end

  if Flipflop.v2?
    class RelatedItemType < Types::BaseObject
      field :kind, String, null: true, deprecation_reason: 'Use `relationship`'
      field :value, [String], null: true, deprecation_reason: 'Use `description, uri, or item_type`'
      field :description, String, description: 'Description of the related item'
      field :item_type, String, description: 'Type of related item'
      field :relationship, String, description: 'How the item is related'
      field :uri, String, description: 'URI for the related item, if applicable'

      def kind
        @object['relationship']
      end

      def value
        [
          @object['description'],
          @object['item_type'],
          @object['uri']
        ].compact
      end
    end
  else
    class RelatedItemType < Types::BaseObject
      field :kind, String, null: true
      field :value, [String], null: false
    end
  end

  if Flipflop.v2?
    class VersionType < Types::BaseObject
      field :distribution, String, null: false
      field :number, String, null: false
      field :lucene_version, String, null: false
    end

    class InfoType < Types::BaseObject
      field :name, String, null: false
      field :tagline, String, null: false
      field :version, Types::VersionType, null: false
    end

    class IdentiferType < Types::BaseObject
      field :kind, String, null: false, description: 'Type of identifier'
      field :value, String, null: false, description: 'Value of identifier'
    end

    class DateRange < Types::BaseObject
      field :gte, String, null: true, description: 'Beginning of date range'
      field :lte, String, null: true, description: 'End of date range'
    end

    class DateType < Types::BaseObject
      field :kind, String, null: false, description: 'Type of date; e.g., "creation", "accessioned", etc.'
      field :note, String, null: true, description: 'Notes about the date, if applicable'
      field :range, Types::DateRange, null: true, description: 'Range of dates'
      field :value, String, null: true,
                            description: 'Value of date. Note that date ranges will be returned in the `range` subfield'
    end

    class RightsType < Types::BaseObject
      field :description, String, null: true, description: 'Description of rights statement'
      field :kind, String, null: true, description: 'Type of rights statement'
      field :uri, String, null: true, description: 'Link to additional information about rights statement'
    end

    class FundingType < Types::BaseObject
      field :award_number, String, description: 'Grant award number'
      field :award_uri, String, description: 'Grant award URI'
      field :funder_identifier, String, description: 'Unique identifier for funding source'
      field :funder_identifier_type, String, description: 'Type of unique indentifier for funding source'
      field :funder_name, String, description: 'Name of funding source'
    end

    # Warning: cannot deprecate old Notes properly without renaming
    class NoteType < Types::BaseObject
      field :kind, String, description: 'Type of note'
      field :value, [String], description: 'Value of note'
    end

    # Warning: cannot deprecate old Subjects properly without renaming
    class SubjectType < Types::BaseObject
      field :kind, String, description: 'Type of subject term'
      field :value, [String], description: 'Value of subject term'
    end

    # Warning: cannot deprecate old AlternateTitles properly without renaming
    class AlternateTitleType < Types::BaseObject
      field :kind, String, description: 'Type of alternate title'
      field :value, String, description: 'Value of alternate title'
    end

    # Warning: related_place was supposed to be an array but was incorrectly a string in grapql for v1
    class LocationType < Types::BaseObject
      field :geopoint, String, description: 'GeoPoint data for the location, if applicable'
      field :kind, String, description: 'Type of location'
      field :value, String, description: 'Name of location'
    end

    class HighlightType < Types::BaseObject
      field :matched_field, String, description: 'The field that was matched by search terms'
      field :matched_phrases, [String], description: 'The phrases within a field that were matched'

      def matched_field
        @object.first
      end

      def matched_phrases
        @object.drop(1).flatten!
      end
    end
  end

  if Flipflop.v2?
    # Warning: cannot deprecate old content_type properly without renaming (was string, now is [string])

    class RecordType < Types::BaseObject
      field :identifier, ID, null: false, deprecation_reason: 'Use `timdex_record_id`'
      field :timdex_record_id, ID, null: false, description: 'TIMDEX unique identifier for the item'
      field :source, String, null: false,
                             description: 'Name of source record system'
      field :source_link, String, null: false, description: 'URL for source record in source system'
      field :title, String, null: false, description: 'Title of item'
      field :alternate_titles, [Types::AlternateTitleType], null: true, description: 'Alternate titles for the item'
      field :contributors, [Types::ContributorType], null: true,
                                                     description: 'Contributors to the item; e.g., authors, editors, etc.'
      field :subjects, [Types::SubjectType], null: true, description: 'Subject terms for item'
      field :identifiers, [Types::IdentiferType], null: true,
                                                  description: 'Unique identifiers associated with the item; e.g., ISBN, DOI, etc.'
      field :isbns, [String], null: true, deprecation_reason: 'Use `identifiers`'
      field :issns, [String], null: true, deprecation_reason: 'Use `identifiers`'
      field :dois, [String], null: true, deprecation_reason: 'Use `identifiers`'
      field :oclcs, [String], null: true, deprecation_reason: 'Use `identifiers`'
      field :lccn, String, null: true, deprecation_reason: 'Use `identifiers`'
      field :place_of_publication, String, null: true, deprecation_reason: 'Use `locations`'
      field :languages, [String], null: true, description: 'Language(s) of item'
      field :publication_date, String, null: true, deprecation_reason: 'Use `dates`'
      field :content_type, [String], null: true,
                                     description: 'Type of content of item; e.g., "still image", "text", etc.'
      field :call_numbers, [String], null: true, description: 'Identification number used to classify and locate item'
      field :citation, String, null: true, description: 'Citation for item'
      field :edition, String, null: true, description: 'Edition information for item'
      field :imprint, [String], null: true, deprecation_reason: 'Use `publicationInformation`'
      field :publication_information, [String], description: 'Imprint information for item'
      field :physical_description, String, null: true, description: 'Physical description of item'
      field :publication_frequency, [String], null: true,
                                              description: 'Publication frequency of item (used for serials)'
      field :numbering, String, null: true
      field :notes, [Types::NoteType], null: true, description: 'Notes about item from source record'
      field :contents, [String], null: true, description: 'Table of contents for item'
      field :summary, [String], null: true,
                                description: 'Summary of contents of item (also where abstract goes if applicable)'
      field :format, [String], null: true, description: 'Format of item e.g. "Print Volume", "DVD", etc.'
      field :literary_form, String, null: true, description: 'Identifies the item as fiction or nonfiction'
      field :related_place, [String], null: true, deprecation_reason: 'Use `locations`'
      field :in_bibliography, [String], null: true, deprecation_reason: 'Use `related_items`'
      field :related_items, [Types::RelatedItemType], null: true,
                                                      description: 'Items that are related to the item in some way'
      field :links, [Types::LinkType], null: true, description: 'Link(s) to item'
      field :holdings, [Types::HoldingType], null: true, description: 'Local holdings of the item'
      field :dates, [Types::DateType], null: true, description: 'Dates associated with item, including publication date'
      field :rights, [Types::RightsType], null: true, description: 'Rights information for the item'
      field :file_formats, [String], null: true, description: 'Available file formats for the item'
      field :funding_information, [Types::FundingType], null: true, description: 'Funding information for the item'
      field :locations, [Types::LocationType], null: true,
                                               description: 'Places associated with item, including location of publication'
      field :highlight, [Types::HighlightType], null: true, description: 'Search term matches in item metadata'
      field :score, String, null: true, description: 'Search relevance'

      def in_bibliography
        @object['related_items']&.map { |i| i['uri'] if i['relationship'] == 'IsCitedBy' }&.compact
      end

      def place_of_publication
        @object['locations']&.map { |place| place['value'] if place['kind'] == 'Place of publication' }&.compact&.first
      end

      def related_place
        @object['locations']&.map { |place| place['value'] if place['kind'] != 'Place of publication' }&.compact
      end

      def publication_date
        @object['dates'].map { |date| date['value'] if date['kind'] == 'Publication date' }.compact&.first
      end

      def file_formats
        @object['file_formats'].uniq
      end

      def imprint
        @object['publication_information']
      end

      def identifier
        @object['timdex_record_id']
      end

      def oclcs
        deprecated_identifiers('oclc')
      end

      def isbns
        deprecated_identifiers('isbn')
      end

      def issns
        deprecated_identifiers('issn')
      end

      def lccn
        deprecated_identifiers('lccn')&.first
      end

      def dois
        deprecated_identifiers('DOI')
      end

      def deprecated_identifiers(field)
        @object['identifiers'].map { |id| id['value'] if id['kind'] == field }.compact
      end
    end
  else
    class RecordType < Types::BaseObject
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
end
