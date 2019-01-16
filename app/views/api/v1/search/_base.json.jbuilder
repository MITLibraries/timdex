json.id result['identifier']
json.source result['source']
json.source_link result['source_link']
json.full_record_link api_v1_record_url(result['identifier'])
json.content_type result['content_type']
json.content_format result['format'] if result['format']
json.realtime_holdings_link 'Not Yet Implemented'
json.publication_date result['publication_date']
json.title result['title']
json.links result['links'] if result['links']
json.authors result['creators']
json.subjects result['subjects']
json.summary_holdings result['holdings'] if result['holdings']
