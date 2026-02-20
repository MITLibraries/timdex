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

  # Calculate the size parameter for the query, allowing override via per_page parameter
  def calculate_size
    if @params && @params[:per_page]
      per_page = @params[:per_page].to_i
      per_page = SIZE if per_page <= 0
      [per_page, MAX_SIZE].min
    else
      SIZE
    end
  end

  # Construct the json query to send to elasticsearch
  def build_query(from)
    query_hash = {
      from:,
      size: calculate_size,
      query:,
      aggregations: Aggregations.all,
      sort: sort_builder.build
    }

    source = source_builder.build
    query_hash[:_source] = source if source.present?

    highlight = highlight_builder.build
    query_hash[:highlight] = highlight if @highlight

    query_hash.to_json
  end

  # Build the query portion of the elasticsearch json
  def query
    @query_strategy ||= LexicalQueryBuilder.new
    @query_strategy.build(@params, @fulltext)
  end

  def sort_builder
    @sort_builder ||= SortBuilder.new
  end

  def source_builder
    @source_builder ||= SourceBuilder.new
  end

  def highlight_builder
    @highlight_builder ||= HighlightBuilder.new
  end
end
