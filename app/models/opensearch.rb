# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
class Opensearch
  SIZE = 20
  MAX_SIZE = 200

  def search(from, params, client, highlight = false, index = nil, fulltext = false)
    @params = params
    @highlight = highlight
    @fulltext = fulltext?(fulltext)
    index = default_index unless index.present?
    client.search(index:,
                  body: build_query(from))
  end

  # Only treat fulltext as true if it is boolean true or the string 'true' (case insensitive)
  def fulltext?(fulltext_param)
    fulltext_param == true || fulltext_param.to_s.downcase == 'true'
  end

  def default_index
    ENV.fetch('OPENSEARCH_INDEX', nil)
  end

  # Construct the json query to send to elasticsearch
  def build_query(from)
    # allow overriding the OpenSearch `size` via params (per_page), capped by MAX_PAGE
    calculate_size = if @params && @params[:per_page]
                       per_page = @params[:per_page].to_i
                       per_page = SIZE if per_page <= 0
                       [per_page, MAX_SIZE].min
                     else
                       SIZE
                     end

    query_hash = {
      from:,
      size: calculate_size,
      query:,
      aggregations: Aggregations.all,
      sort:
    }

    # If ENV OPENSEARCH_SOURCE_EXCLUDES is set, use the values in it's comma-separated list;
    #   otherwise leave out the _source attribute entirely (which will return all fields in _source)
    # excludes are used to prevent large fields from being returned in the search results, which can cause performance issues
    # these fields are still searchable, just not returned in the search results
    if ENV['OPENSEARCH_SOURCE_EXCLUDES'].present?
      query_hash[:_source] = {
        excludes: ENV['OPENSEARCH_SOURCE_EXCLUDES'].split(',').map(&:strip)
      }
    end

    query_hash[:highlight] = highlight if @highlight
    query_hash.to_json
  end

  # Build the query portion of the elasticsearch json
  def query
    @query_strategy ||= LexicalQueryBuilder.new
    @query_strategy.build(@params, @fulltext)
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
end
