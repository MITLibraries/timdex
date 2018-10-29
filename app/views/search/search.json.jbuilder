json.hits @results['hits']['total']

json.results @results['hits']['hits'] do |result|
  json.partial! partial: 'base', locals: { result: result['_source'] }
end
