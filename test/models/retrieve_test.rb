require 'test_helper'

class RetrieveTest < ActiveSupport::TestCase
  test 'graphqlv2 uses correct index for retrieve queries' do
    assert_equal ENV.fetch('OPENSEARCH_INDEX'), Retrieve.new.default_index
  end
end
