require 'test_helper'

class RetrieveTest < ActiveSupport::TestCase
  def setup
    @test_strategy = Flipflop::FeatureSet.current.test!
  end

  test 'graphlv1 uses correct index for retrieve queries' do
    @test_strategy.switch!(:v2, false)
    assert_equal ENV.fetch('ELASTICSEARCH_INDEX'), Retrieve.new.default_index
  end

  test 'graphqlv2 uses correct index for retrieve queries' do
    @test_strategy.switch!(:v2, true)
    assert_equal ENV.fetch('OPENSEARCH_INDEX'), Retrieve.new.default_index
  end
end
