class Opensearch
  SIZE = 20
  MAX_PAGE = 200

  def search(from, params, client)
    @params = params
    client.search(index: ENV.fetch('ELASTICSEARCH_INDEX', nil),
                  body: build_query(from))
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
        filter: filters
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
  def filters
    f = []
    f.push filter(@params[:collection_facet], 'collections') if @params[:collection_facet]
    f.push filter(@params[:contributors_facet], 'contributors') if @params[:contributors_facet]

    f.push filter_single(@params[:content_type_facet], 'content_type') if @params[:content_type_facet]

    f.push filter(@params[:content_format_type], 'format') if @params[:content_format_type]

    f.push filter(@params[:languages_facet], 'languages') if @params[:languages_facet]

    f.push filter_single(@params[:literary_form_facet], 'literary_form') if @params[:literary_form_facet]

    f.push filter_sources(@params[:source_facet]) if @params[:source_facet]

    f.push filter(@params[:subjects_facet], 'subjects') if @params[:subjects_facet]
    f
  end

  # use `filter` when we accept multiple of the same parameter in our data
  # model
  def filter(param, field)
    terms = []

    param.each do |t|
      if field == 'contributors'
        terms.push(
          nested: {
            path: 'contributors',
            query: {
              bool: {
                must: [{
                  match: {
                    'contributors.value.keyword': t
                  }
                }]
              }
            }
          }
        )
      else
        terms.push(term: { "#{field}.keyword": t })
      end
    end

    terms
  end

  # use `filter_single` when we only accept a single value in our data model
  def filter_single(param, field)
    {
      term: { "#{field}": param }
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
      collections: {
        terms: {
          field: 'collections.keyword'
        }
      },
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
