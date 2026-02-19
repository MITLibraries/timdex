class LexicalQueryBuilder
  def build(params, fulltext = false)
    {
      bool: {
        should: multisearch(params),
        must: matches(params, fulltext),
        filter: FilterBuilder.new.build(params)
      }
    }
  end

  private

  def multisearch(params)
    return unless params[:q].present?

    [
      {
        prefix: {
          'title.exact_value': {
            value: params[:q].downcase,
            boost: 15.0
          }
        }
      },
      {
        term: {
          title: {
            value: params[:q].downcase,
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
                value: params[:q].downcase,
                boost: 0.1
              }
            }
          }
        }
      }
    ]
  end

  def matches(params, fulltext = false)
    m = []
    if params[:q].present?
      m << {
        multi_match: {
          query: params[:q].downcase,
          fields: fields_to_search(fulltext),
          minimum_should_match: minimum_should_match(params[:boolean_type])
        }
      }
    end
    match_single_field(:citation, params, m)
    match_single_field(:title, params, m)

    match_single_field_nested(:contributors, params, m)
    match_single_field_nested(:funding_information, params, m)
    match_single_field_nested(:identifiers, params, m)
    match_single_field_nested(:locations, params, m)
    match_single_field_nested(:subjects, params, m)

    match_geodistance(params, m) if params[:geodistance].present?
    match_geobox(params, m) if params[:geobox].present?
    m
  end

  # https://opensearch.org/docs/latest/query-dsl/geo-and-xy/geo-bounding-box/
  def match_geobox(params, match_array)
    match_array << {
      bool: {
        must: {
          match_all: {}
        },
        filter: {
          geo_bounding_box: {
            'locations.geoshape': {
              top: params[:geobox][:max_latitude],
              bottom: params[:geobox][:min_latitude],
              left: params[:geobox][:min_longitude],
              right: params[:geobox][:max_longitude]
            }
          }
        }
      }
    }
  end

  # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-geo-distance-query.html
  # Note: at the time of this implementation, opensearch does not have documentation on
  # this features hence the link to the prefork elasticsearch docs
  def match_geodistance(params, match_array)
    match_array << {
      bool: {
        must: {
          match_all: {}
        },
        filter: {
          geo_distance: {
            distance: params[:geodistance][:distance],
            'locations.geoshape': {
              lat: params[:geodistance][:latitude],
              lon: params[:geodistance][:longitude]
            }
          }
        }
      }
    }
  end

  # https://opensearch.org/docs/latest/query-dsl/minimum-should-match/#valid-values
  # checks for preconfigured cases or uses whatever is supplied (i.e. we currently accept OpenSearch syntax for
  # minimum_should_match)
  def minimum_should_match(boolean_type)
    case boolean_type
    when 'OR'
      '0%'
    when 'AND'
      '100%'
    # 5 or less terms match all (AND)
    # More than 5 match all but one
    when 'experiment_a'
      '4<100% 5<-1'
    # 4 or less terms match all (AND)
    # More than 4 match all but one
    when 'experiment_b'
      '3<100% 4<-1'
    # 4 or less terms match all (AND)
    # 5 to 10 match all but one
    # 10 or more match 90%
    when 'experiment_c'
      '3<100% 9<-1 10<90%'
    else
      boolean_type
    end
  end

  # Fields to be searched in multi_match query. Adds 'fulltext' field if fulltext search is enabled.
  def fields_to_search(fulltext)
    fields = ['alternate_titles', 'call_numbers', 'citation', 'contents', 'contributors.value', 'dates.value',
              'edition', 'funding_information.*', 'identifiers.value', 'languages', 'locations.value',
              'notes.value', 'numbering', 'publication_information', 'subjects.value', 'summary', 'title']
    fields << 'fulltext' if fulltext

    fields
  end

  def match_single_field(field, params, match_array)
    return unless params[field]

    match_array << {
      match: {
        field => params[field].downcase
      }
    }
  end

  def match_single_field_nested(field, params, match_array)
    return unless params[field]

    match_array << {
      nested: {
        path: field.to_s,
        query: {
          bool: {
            must: [
              { match: { "#{field}.#{nested_field(field)}": params[field].downcase } }
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
