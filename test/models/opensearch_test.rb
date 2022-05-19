require 'test_helper'

class OpensearchTest < ActiveSupport::TestCase
  test 'matches citation' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { citation: 'foo' })
    assert os.matches.select { |m| m[:citation] == 'foo' }
  end

  test 'matches title' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { title: 'foo' })
    assert os.matches.select { |m| m[:title] == 'foo' }
  end

  test 'matches contributors' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { contributors: 'foo' })
    assert os.matches.select { |m| m['contributors.value'] == 'foo' }
  end

  test 'matches funding_information' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { funding_information: 'foo' })
    assert os.matches.select { |m| m['funding_information.funder_name'] == 'foo' }
  end

  test 'matches identifiers' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { identifiers: 'foo' })
    assert os.matches.select { |m| m['identifiers.value'] == 'foo' }
  end

  test 'matches locations' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { locations: 'foo' })
    assert os.matches.select { |m| m['locations.value'] == 'foo' }
  end

  test 'matches subjects' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { subjects: 'foo' })
    assert os.matches.select { |m| m['subjects.value'] == 'foo' }
  end

  test 'matches everything' do
    os = Opensearch.new
    os.instance_variable_set(:@params, { q: 'this', citation: 'here', title: 'is', contributors: 'a',
                                         funding_information: 'real', identifiers: 'search', locations: 'rest',
                                         subjects: 'assured,' })
    matches = os.matches
    assert matches.select { |m| m[:q] == 'this' }
    assert matches.select { |m| m[:citation] == 'here' }
    assert matches.select { |m| m[:title] == 'is' }
    assert matches.select { |m| m['contributors.value'] == 'a' }
    assert matches.select { |m| m['funding_information.funder_name'] == 'real' }
    assert matches.select { |m| m['identifiers.value'] == 'search' }
    assert matches.select { |m| m['locations.value'] == 'rest' }
    assert matches.select { |m| m['subjects.value'] == 'assured' }
  end

  test 'searches a single field' do
    VCR.use_cassette('opensearch single field') do
      params = { title: 'spice' }
      results = Opensearch.new.search(0, params, Timdex::OSClient)
      assert_equal "Spice it up! the best of Paquito D'Rivera.",
                   results['hits']['hits'].first['_source']['title']
    end
  end

  test 'searches a single field with nested subfields' do
    VCR.use_cassette('opensearch single field nested') do
      params = { contributors: 'mcternan' }
      results = Opensearch.new.search(0, params, Timdex::OSClient)
      assert_equal "A common table : 80 recipes and stories from my shared cultures /",
                   results['hits']['hits'].first['_source']['title']
    end
  end

  test 'searches multiple fields' do
    VCR.use_cassette('opensearch multiple fields') do
      params = { q: 'chinese', title: 'common', contributors: 'mcternan'}
      results = Opensearch.new.search(0, params, Timdex::OSClient)
      assert_equal "A common table : 80 recipes and stories from my shared cultures /",
                   results['hits']['hits'].first['_source']['title']
    end
  end
end
