json.hits @results['hits']['total']
json.partial! partial: 'throttle'

if @results['hits']['total']['value'].positive? && @results['hits']['hits'].count.zero?
  json.error 'Invalid page parameter: requested page past last result'
else

  json.results @results['hits']['hits'] do |result|
    json.partial! partial: 'base', locals: { result: result['_source'] }
    if params[:full].present? && params[:full].downcase != 'false'
      json.partial! partial: 'extended', locals: { result: result['_source'] }
    end
  end

  json.partial! partial: 'aggregations'
end
