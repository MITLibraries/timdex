json.hits @results['hits']['total']

if @results['hits']['total'].positive? && @results['hits']['hits'].count.zero?
  json.error 'Invalid page parameter: requested page past last result'
else

  json.results @results['hits']['hits'] do |result|
    json.partial! partial: 'base', locals: { result: result['_source'] }
  end

  json.partial! partial: 'aggregations'
end
