result = @results['hits']['hits'][0]['_source']
json.partial! partial: 'throttle'
json.partial! partial: 'base', locals: { result: result }
json.partial! partial: 'extended', locals: { result: result }
