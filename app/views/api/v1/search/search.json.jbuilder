json.hits @results['hits']['total']

if @results['hits']['total'].positive? && @results['hits']['hits'].count.zero?
  json.error 'Invalid page parameter: requested page past last result'
else
  json.aggregations do
    json.languages @results['aggregations']['languages']['buckets'] do |x|
      json.name x['key']
      json.count x['doc_count']
    end

    json.content_type @results['aggregations']['content_type']['buckets'] do |x|
      json.name x['key']
      json.count x['doc_count']
    end

    json.authors @results['aggregations']['creators']['buckets'] do |x|
      json.name x['key']
      json.count x['doc_count']
    end
    
    json.subjects @results['aggregations']['subjects']['buckets'] do |x|
      json.name x['key']
      json.count x['doc_count']
    end

    json.content_format @results['aggregations']['content_format']['buckets'] do |x|
      json.name x['key']
      json.count x['doc_count']
    end

    json.literary_form @results['aggregations']['literary_form']['buckets'] do |x|
      json.name x['key']
      json.count x['doc_count']
    end

    json.source @results['aggregations']['source']['buckets'] do |x|
      json.name x['key']
      json.count x['doc_count']
    end
  end

  json.results @results['hits']['hits'] do |result|
    json.partial! partial: 'base', locals: { result: result['_source'] }
  end
end
