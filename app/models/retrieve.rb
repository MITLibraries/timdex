class Retrieve
  def fetch(id, client, index = nil)
    f = to_filter(id)

    index = default_index unless index.present?

    record = client.search(index: index, body: f)

    raise OpenSearch::Transport::Transport::Errors::NotFound if record['hits']['total']['value'].zero?

    record
  end

  def default_index
    ENV.fetch('OPENSEARCH_INDEX', nil)
  end

  def to_filter(id)
    {
      query: {
        ids: {
          values: [id]
        }
      }
    }.to_json
  end
end
