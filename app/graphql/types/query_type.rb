module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: 'An example field added by the generator'

    def test_field
      'Hello World!'
    end

    field :record_id, String, null: false, description: 'timdex record id'

    def record_id
      'huh'
    end

    field :all_records, [RecordType], null: false

    def all_records
      # response = Faraday.get 'https://timdex.mit.edu/api/v1/search?q=popcorn'
      # JSON.parse(response.body)['results']
      query = {}
      query[:q] = 'popcorn'
      a = Search.search(1, 10, query)

      a['hits']['hits'].map{ |x| x['_source']}
    end
  end
end
