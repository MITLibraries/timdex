# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
class Aggregations
  # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html
  def self.all
    {
      access_to_files:,
      contributors:,
      content_type:,
      content_format:,
      languages:,
      literary_form:,
      places:,
      source:,
      subjects:
    }
  end

  # Return only the aggregations that were requested
  # @param requested_names [Array<Symbol>] Array of aggregation names to include (e.g., [:source, :contributors])
  # @return [Hash] Filtered aggregations hash with only requested aggregations
  def self.for_request(requested_names)
    return {} if requested_names.nil? || requested_names.empty?

    all_aggs = all
    requested_names.each_with_object({}) do |name, result|
      result[name] = all_aggs[name] if all_aggs.key?(name)
    end
  end

  def self.access_to_files
    {
      nested: {
        path: 'rights'
      },
      aggs: {
        only_file_access: {
          filter: {
            terms: {
              'rights.kind': [
                'Access to files'
              ]
            }
          },
          aggs: {
            access_types: {
              terms: {
                field: 'rights.description.keyword'
              }
            }
          }
        }
      }
    }
  end

  def self.contributors
    {
      nested: {
        path: 'contributors'
      },
      aggs: {
        contributor_names: {
          terms: {
            field: 'contributors.value.keyword'
          }
        }
      }
    }
  end

  def self.content_type
    {
      terms: {
        field: 'content_type'
      }
    }
  end

  def self.content_format
    {
      terms: {
        field: 'format'
      }
    }
  end

  def self.languages
    {
      terms: {
        field: 'languages.keyword'
      }
    }
  end

  def self.literary_form
    {
      terms: {
        field: 'literary_form'
      }
    }
  end

  def self.source
    {
      terms: {
        field: 'source'
      }
    }
  end

  def self.subjects
    {
      nested: {
        path: 'subjects'
      },
      aggs: {
        subject_names: {
          terms: {
            field: 'subjects.value.keyword'
          }
        }
      }
    }
  end

  def self.places
    {
      nested: {
        path: 'subjects'
      },
      aggs: {
        only_spatial: {
          filter: {
            terms: {
              'subjects.kind': [
                'Dublin Core; Spatial'
              ]
            }
          },
          aggs: {
            place_names: {
              terms: {
                field: 'subjects.value.keyword'
              }
            }
          }
        }
      }
    }
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/MethodLength
