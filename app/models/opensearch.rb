class Opensearch
  SIZE = 20
  MAX_PAGE = 200

  def search(from, params, client, index = nil)
    @params = params
    index = default_index unless index.present?
    client.search(index: index,
                  body: build_query(from))
  end

  def default_index
    ENV.fetch('OPENSEARCH_INDEX', nil)
  end

  # Construct the json query to send to elasticsearch
  def build_query(from)
    {
      from: from,
      size: SIZE,
      query: query,
      highlight: highlight,
      aggregations: aggregations
    }.to_json
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
          query: @params[:q].downcase
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
    m
  end

  # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
  def filters(params)
    f = []

    if params[:contributors_facet].present?
      params[:contributors_facet].each do |p|
        f.push filter_field_by_value('contributors.value.keyword', p)
      end
    end

    if params[:content_type_facet].present?
      params[:content_type_facet].each do |p|
        f.push filter_field_by_value('content_type', p)
      end
    end

    if params[:content_format_facet].present?
      params[:content_format_facet].each do |p|
        f.push filter_field_by_value('format', p)
      end
    end

    if params[:languages_facet].present?
      params[:languages_facet].each do |p|
        f.push filter_field_by_value('languages', p)
      end
    end

    # literary_form is a single value aggregation
    f.push filter_field_by_value('literary_form', params[:literary_form_facet]) if params[:literary_form_facet].present?

    # source aggregation is "OR" and not "AND" so it does not use the filter_field_by_value method
    f.push filter_sources(params[:source_facet]) if params[:source_facet]

    if params[:subjects_facet].present?
      params[:subjects_facet].each do |p|
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
          source: source
        }
      }
    end
    sources
  end

  # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html
  def aggregations
    {
      contributors: {
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
      },
      content_type: {
        terms: {
          field: 'content_type'
        }
      },
      content_format: {
        terms: {
          field: 'format'
        }
      },
      languages: {
        terms: {
          field: 'languages.keyword'
        }
      },
      literary_form: {
        terms: {
          field: 'literary_form'
        }
      },
      source: {
        terms: {
          field: 'source'
        }
      },
      subjects: {
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
    }
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
