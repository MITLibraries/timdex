# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
class Aggregations
  # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html
  def self.all
    {
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
