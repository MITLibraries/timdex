module Types
  class LinkType < Types::BaseObject
    field :kind, String, null: true
    field :text, String, null: true
    field :url, String, null: false
    field :restrictions, String, null: true
  end

  if Flipflop.v2?
    class ContributorType < Types::BaseObject
      field :kind, String, null: true
      field :value, String, null: false
      field :identifier, [String], null: true
      field :affiliation, [String], null: true
      field :mit_affiliated, Boolean, null: true
    end
  else
    class ContributorType < Types::BaseObject
      field :kind, String, null: true
      field :value, String, null: false
    end
  end

  class HoldingType < Types::BaseObject
    field :location, String, null: false
    field :collection, String, null: true
    field :callnumber, String, null: true
    field :summary, String, null: true
    field :notes, String, null: true
    field :format, String, null: true
  end

  if Flipflop.v2?
    class RelatedItemType < Types::BaseObject
      field :kind, String, null: true, deprecation_reason: 'Use `relationship`'
      field :value, [String], null: true, deprecation_reason: 'Use `description, uri, or item_type`'
      field :description, String
      field :item_type, String
      field :relationship, String
      field :uri, String

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
      field :kind, String, null: false
      field :value, String, null: false
    end

    class DateRange < Types::BaseObject
      field :gte, String, null: true
      field :lte, String, null: true
    end

    class DateType < Types::BaseObject
      field :kind, String, null: false
      field :note, String, null: true
      field :range, Types::DateRange, null: true
      field :value, String, null: true
    end

    class RightsType < Types::BaseObject
      field :description, String, null: true
      field :kind, String, null: true
      field :uri, String, null: true
    end

    class FundingType < Types::BaseObject
      field :award_number, String
      field :award_uri, String
      field :funder_identifier, String
      field :funder_identifier_type, String
      field :funder_name, String
    end

    # Warning: cannot deprecate old Notes properly without renaming
    class NoteType < Types::BaseObject
      field :kind, String
      field :value, [String]
    end

    # Warning: cannot deprecate old Subjects properly without renaming
    class SubjectType < Types::BaseObject
      field :kind, String
      field :value, [String]
    end

    # Warning: cannot deprecate old AlternateTitles properly without renaming
    class AlternateTitleType < Types::BaseObject
      field :kind, String
      field :value, String
    end

    # Warning: related_place was supposed to be an array but was incorrectly a string in grapql for v1
    class LocationType < Types::BaseObject
      field :geopoint, String
      field :kind, String
      field :value, String
    end
  end

  if Flipflop.v2?
    # Warning: cannot deprecate old content_type properly without renaming (was string, now is [string])

    class RecordType < Types::BaseObject
      field :identifier, String, null: false, deprecation_reason: 'Use `timdex_record_id`'
      field :timdex_record_id, ID, null: false
      field :source, String, null: false
      field :source_link, String, null: false
      field :title, String, null: false
      field :alternate_titles, [Types::AlternateTitleType], null: true
      field :contributors, [Types::ContributorType], null: true
      field :subjects, [Types::SubjectType], null: true
      field :identifiers, [Types::IdentiferType], null: true
      field :isbns, [String], null: true, deprecation_reason: 'Use `identifiers`'
      field :issns, [String], null: true, deprecation_reason: 'Use `identifiers`'
      field :dois, [String], null: true, deprecation_reason: 'Use `identifiers`'
      field :oclcs, [String], null: true, deprecation_reason: 'Use `identifiers`'
      field :lccn, String, null: true, deprecation_reason: 'Use `identifiers`'
      field :place_of_publication, String, null: true, deprecation_reason: 'Use `locations`'
      field :languages, [String], null: true
      field :publication_date, String, null: true, deprecation_reason: 'Use `dates`'
      field :content_type, [String], null: true
      field :call_numbers, [String], null: true
      field :edition, String, null: true
      field :imprint, [String], null: true, deprecation_reason: 'Use `publicationInformation`'
      field :publication_information, [String]
      field :physical_description, String, null: true
      field :publication_frequency, [String], null: true
      field :numbering, String, null: true
      field :notes, [Types::NoteType], null: true
      field :contents, [String], null: true
      field :summary, [String], null: true
      field :format, [String], null: true
      field :literary_form, String, null: true
      field :related_place, [String], null: true, deprecation_reason: 'Use `locations`'
      field :in_bibliography, [String], null: true, deprecation_reason: 'Use `related_items`'
      field :related_items, [Types::RelatedItemType], null: true
      field :links, [Types::LinkType], null: true
      field :holdings, [Types::HoldingType], null: true
      field :dates, [Types::DateType], null: true
      field :rights, [Types::RightsType], null: true
      field :file_formats, [String], null: true
      field :funding_information, [Types::FundingType], null: true
      field :locations, [Types::LocationType], null: true

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
