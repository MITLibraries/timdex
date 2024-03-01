# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
class Opensearch
  SIZE = 20
  MAX_PAGE = 200

  def search(from, params, client, highlight = false, index = nil)
    @params = params
    @highlight = highlight
    index = default_index unless index.present?
    client.search(index:,
                  body: build_query(from))
  end

  def default_index
    ENV.fetch('OPENSEARCH_INDEX', nil)
  end

  # Construct the json query to send to elasticsearch
  def build_query(from)
    query_hash = {
      from:,
      size: SIZE,
      query:,
      aggregations: Aggregations.all,
      sort:
    }

    query_hash[:highlight] = highlight if @highlight
    query_hash.to_json
  end

  # Build the query portion of the elasticsearch json
  def query
    {
      bool: {
        should: multisearch,
        must: matches,
        filter: filters(@params)
      }
    }
  end

  def sort
    [
      { _score: { order: 'desc' } },
      {
        'dates.value.as_date': {
          order: 'desc',
          nested: {
            path: 'dates'
          }
        }
      }
    ]
  end

  def highlight
    {
      pre_tags: [
        '<span class="highlight">'
      ],
      post_tags: [
        '</span>'
      ],
      fields: {
        '*': {}
      }
    }
  end

  def multisearch
    return unless @params[:q].present?

    [
      {
        prefix: {
          'title.exact_value': {
            value: @params[:q].downcase,
            boost: 15.0
          }
        }
      },
      {
        term: {
          title: {
            value: @params[:q].downcase,
            boost: 1.0
          }
        }
      },
      {
        nested: {
          path: 'contributors',
          query: {
            term: {
              'contributors.value': {
                value: @params[:q].downcase,
                boost: 0.1
              }
            }
          }
        }
      }
    ]
  end

  def matches
    m = []
    if @params[:q].present?
      m << {
        multi_match: {
          query: @params[:q].downcase,
          fields: ['alternate_titles', 'call_numbers', 'citation', 'contents', 'contributors.value', 'dates.value',
                   'edition', 'funding_information.*', 'identifiers.value', 'languages', 'locations.value',
                   'notes.value', 'numbering', 'publication_information', 'subjects.value', 'summary', 'title']
        }
      }
    end
    match_single_field(:citation, m)
    match_single_field(:title, m)

    match_single_field_nested(:contributors, m)
    match_single_field_nested(:funding_information, m)
    match_single_field_nested(:identifiers, m)
    match_single_field_nested(:locations, m)
    match_single_field_nested(:subjects, m)

    match_geodistance(m) if @params[:geodistance].present?
    match_geobox(m) if @params[:geobox].present?
    m
  end

  # https://opensearch.org/docs/latest/query-dsl/geo-and-xy/geo-bounding-box/
  def match_geobox(match_array)
    match_array << {
      bool: {
        must: {
          match_all: {}
        },
        filter: {
          geo_bounding_box: {
            'locations.geoshape': {
              top: @params[:geobox][:max_latitude],
              bottom: @params[:geobox][:min_latitude],
              left: @params[:geobox][:min_longitude],
              right: @params[:geobox][:max_longitude]
            }
          }
        }
      }
    }
  end

  # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-geo-distance-query.html
  # Note: at the time of this implementation, opensearch does not have documentation on
  # this features hence the link to the prefork elasticsearch docs
  def match_geodistance(match_array)
    match_array << {
      bool: {
        must: {
          match_all: {}
        },
        filter: {
          geo_distance: {
            distance: @params[:geodistance][:distance],
            'locations.geoshape': {
              lat: @params[:geodistance][:latitude],
              lon: @params[:geodistance][:longitude]
            }
          }
        }
      }
    }
  end

  # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
  def filters(params)
    f = []

    if params[:contributors_filter].present?
      params[:contributors_filter].each do |p|
        f.push filter_field_by_value('contributors.value.keyword', p)
      end
    end

    if params[:content_type_filter].present?
      params[:content_type_filter].each do |p|
        f.push filter_field_by_value('content_type', p)
      end
    end

    if params[:content_format_filter].present?
      params[:content_format_filter].each do |p|
        f.push filter_field_by_value('format', p)
      end
    end

    if params[:languages_filter].present?
      params[:languages_filter].each do |p|
        f.push filter_field_by_value('languages', p)
      end
    end

    # literary_form is a single value aggregation
    if params[:literary_form_filter].present?
      f.push filter_field_by_value('literary_form',
                                   params[:literary_form_filter])
    end

    # places are really just a subset of subjects so the filter uses the subject field
    if params[:places_filter].present?
      params[:places_filter].each do |p|
        f.push filter_field_by_value('subjects.value.keyword', p)
      end
    end

    # source aggregation is "OR" and not "AND" so it does not use the filter_field_by_value method
    f.push filter_sources(params[:source_filter]) if params[:source_filter]

    # access to files aggregation is "OR" and not "AND" so it does not use the filter_field_by_value method
    f.push filter_access_to_files(params[:access_to_files_filter]) if params[:access_to_files_filter]

    if params[:subjects_filter].present?
      params[:subjects_filter].each do |p|
        f.push filter_field_by_value('subjects.value.keyword', p)
      end
    end

    f
  end

  def filter_field_by_value(field, value)
    {
      term: { "#{field}": value }
    }
  end

  # multiple access to files values are ORd
  def filter_access_to_files(param)
    { nested: {
      path: 'rights',
      query: {
        bool: {
          should: access_to_files_array(param)
        }
      }
    } }
  end

  def access_to_files_array(param)
    rights = []
    param.each do |right|
      rights << {
        term: {
          'rights.description.keyword': right
        }
      }
    end
    rights
  end

  # multiple sources values are ORd
  def filter_sources(param)
    {
      bool: {
        should: source_array(param)
      }
    }
  end

  def source_array(param)
    sources = []
    param.each do |source|
      sources << {
        term: {
          source:
        }
      }
    end
    sources
  end

  private

  def match_single_field(field, match_array)
    return unless @params[field]

    match_array << {
      match: {
        field => @params[field].downcase
      }
    }
  end

  def match_single_field_nested(field, match_array)
    return unless @params[field]

    match_array << {
      nested: {
        path: field.to_s,
        query: {
          bool: {
            must: [
              { match: { "#{field}.#{nested_field(field)}": @params[field].downcase } }
            ]
          }
        }
      }
    }
  end

  # For most nested fields, we only care about 'value'; this handles the exceptions to that rule.
  def nested_field(field)
    if field == :funding_information
      'funder_name'
    else
      'value'
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/MethodLength
