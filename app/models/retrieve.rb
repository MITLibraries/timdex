class Retrieve
  def fetch(id)
    f = to_filter(id)
    record = Timdex::EsClient.search(index: ENV['ELASTICSEARCH_INDEX'], body: f)

    raise Elasticsearch::Transport::Transport::Errors::NotFound if record['hits']['total'].zero?

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
