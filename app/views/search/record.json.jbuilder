result = @results['_source']
json.partial! partial: 'base', locals: { result: result }
json.partial! partial: 'extended', locals: { result: result }
