class Search
  SIZE = 20
  MAX_PAGE = 200

  def search(from, params)
    @params = params
    Timdex::EsClient.search(index: ENV['ELASTICSEARCH_INDEX'],
                            body: build_query(from))
  end

  # Construct the json query to send to elasticsearch
  def build_query(from)
    {
      from: from,
      size: SIZE,
      query: query,
      aggregations: aggregations
    }.to_json
  end

  # Build the query portion of the elasticsearch json
  def query
    {
      bool: {
        should: [
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
        ],
        must: {
          multi_match: {
            query: @params[:q].downcase
          }
        },
        filter: filters
      }
    }
  end

  # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
  def filters
    f = []
    f.push filter(@params[:collection], 'collections') if @params[:collection]
    if @params[:contributors]
      f.push filter(@params[:contributors], 'contributors')
    end

    if @params[:content_type]
      f.push filter_single(@params[:content_type], 'content_type')
    end

    if @params[:content_format]
      f.push filter(@params[:content_format], 'format')
    end

    f.push filter(@params[:language], 'languages') if @params[:language]

    if @params[:literary_form]
      f.push filter_single(@params[:literary_form], 'literary_form')
    end

    f.push filter_single(@params[:source], 'source') if @params[:source]
    f.push filter(@params[:subject], 'subjects') if @params[:subject]
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
        terms.push('term': { "#{field}.keyword": t })
      end
    end

    terms
  end

  # use `filter_single` when we only accept a single value in our data model
  def filter_single(param, field)
    {
      'term': { "#{field}.keyword": param }
    }
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
          field: 'content_type.keyword'
        }
      },
      content_format: {
        terms: {
          field: 'format.keyword'
        }
      },
      languages: {
        terms: {
          field: 'languages.keyword'
        }
      },
      literary_form: {
        terms: {
          field: 'literary_form.keyword'
        }
      },
      source: {
        terms: {
          field: 'source.keyword'
        }
      },
      subjects: {
        terms: {
          field: 'subjects.keyword'
        }
      }
    }
  end
end
