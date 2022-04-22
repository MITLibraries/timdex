class Retrieve
  def fetch(id, client)
    f = to_filter(id)
    record = client.search(index: ENV['ELASTICSEARCH_INDEX'], body: f)

    if client.instance_of?(OpenSearch::Client)
      raise OpenSearch::Transport::Transport::Errors::NotFound if record['hits']['total']['value'].zero?
    else
      raise Elasticsearch::Transport::Transport::Errors::NotFound if record['hits']['total'].zero?
    end

    record
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
