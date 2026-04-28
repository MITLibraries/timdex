require 'test_helper'

class AggregationsTest < ActiveSupport::TestCase
  test 'for_request returns all aggregations when all are requested' do
    requested = %i[access_to_files contributors content_type content_format languages literary_form places source
                   subjects]
    result = Aggregations.for_request(requested)

    assert_equal requested.size, result.size
    requested.each do |agg_name|
      assert result.key?(agg_name)
    end
  end

  test 'for_request returns only requested aggregations' do
    requested = %i[source contributors]
    result = Aggregations.for_request(requested)

    assert_equal 2, result.size
    assert result.key?(:source)
    assert result.key?(:contributors)
  end

  test 'for_request returns empty hash when given empty array' do
    result = Aggregations.for_request([])

    assert_empty result
    assert result.is_a?(Hash)
  end

  test 'for_request returns empty hash when given nil' do
    result = Aggregations.for_request(nil)

    assert_empty result
    assert result.is_a?(Hash)
  end

  test 'for_request ignores invalid aggregation names' do
    requested = %i[source invalid_agg contributors another_invalid]
    result = Aggregations.for_request(requested)

    assert_equal 2, result.size
    assert result.key?(:source)
    assert result.key?(:contributors)
    assert_not result.key?(:invalid_agg)
    assert_not result.key?(:another_invalid)
  end
end
