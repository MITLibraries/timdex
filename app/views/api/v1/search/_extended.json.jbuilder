json.isbns result['isbns'] if result['isbns']
json.issns result['issns'] if result['issns']
json.dois result['dois'] if result['dois']
json.available 'Not Yet Implemented'
json.alternate_titles result['alternate_titles'] if result['alternate_titles']
if json.place_of_publication result['place_of_publication']
  result['place_of_publication']
end
json.languages result['languages'] if result['languages']
json.call_numbers result['call_numbers'] if result['call_numbers']
json.edition result['edition'] if result['edition']
json.imprint result['imprint'] if result['imprint']
if result['physical_description']
  json.physical_description result['physical_description']
end
json.summary result['summary'] if result['summary']
json.imprint result['imprint'] if result['imprint']
json.notes result['notes'] if result['notes']
if result['publication_frequency']
  json.publication_frequency result['publication_frequency']
end
json.literary_form result['literary_form'] if result['literary_form']
