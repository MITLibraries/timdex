require 'test_helper'

class FilterBuilderTest < ActiveSupport::TestCase
  test 'source_array creates correct query structure' do
    sources = ['Zenodo', 'DSpace@MIT']
    expected = [{ term: { source: 'Zenodo' } }, { term: { source: 'DSpace@MIT' } }]

    assert_equal(expected, FilterBuilder.new.source_array(sources))
  end

  test 'filter_sources creates correct query structure' do
    sources = ['Zenodo', 'DSpace@MIT']
    expected = { bool: { should: [{ term: { source: 'Zenodo' } },
                                  { term: { source: 'DSpace@MIT' } }] } }

    assert_equal(expected, FilterBuilder.new.filter_sources(sources))
  end

  test 'access_to_files_array creates correct query structure' do
    rights = ['MIT authentication', 'Free/open to all']
    expected = [{ term: { 'rights.description.keyword': 'MIT authentication' } },
                { term: { 'rights.description.keyword': 'Free/open to all' } }]

    assert_equal(expected, FilterBuilder.new.access_to_files_array(rights))
  end

  test 'filter_access_to_files creates correct query structure' do
    sources = ['MIT authentication', 'Free/open to all']
    expected = { nested: { path: 'rights',
                           query: { bool: { should: [
                             { term: { 'rights.description.keyword': 'MIT authentication' } },
                             { term: { 'rights.description.keyword': 'Free/open to all' } }
                           ] } } } }

    assert_equal(expected, FilterBuilder.new.filter_access_to_files(sources))
  end

  test 'filter_field_by_value query structure' do
    expected = {
      term: { fakefield: 'i am a fake value' }
    }

    assert_equal(expected, FilterBuilder.new.filter_field_by_value('fakefield', 'i am a fake value'))
  end

  test 'build query structure when no filters passed' do
    expected_filters = []
    params = {}

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for single contributors_filter' do
    expected_filters =
      [
        { term: { 'contributors.value.keyword': 'Lastname, Firstname' } }
      ]
    params = { contributors_filter: ['Lastname, Firstname'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for multiple contributors_filter' do
    expected_filters =
      [
        { term: { 'contributors.value.keyword': 'Lastname, Firstname' } },
        { term: { 'contributors.value.keyword': 'Another name' } }
      ]
    params = { contributors_filter: ['Lastname, Firstname', 'Another name'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for single content_type_filter' do
    expected_filters =
      [
        { term: { content_type: 'cheese' } }
      ]
    params = { content_type_filter: ['cheese'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for multiple content_type_filter' do
    expected_filters =
      [
        { term: { content_type: 'cheese' } },
        { term: { content_type: 'ice cream' } }
      ]
    params = { content_type_filter: ['cheese', 'ice cream'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for single content_format_filter' do
    expected_filters =
      [
        { term: { format: 'cheese' } }
      ]
    params = { content_format_filter: ['cheese'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for multiple content_format_filter' do
    expected_filters =
      [
        { term: { format: 'cheese' } },
        { term: { format: 'ice cream' } }
      ]
    params = { content_format_filter: ['cheese', 'ice cream'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for single languages_filter' do
    expected_filters =
      [
        { term: { languages: 'cheese' } }
      ]
    params = { languages_filter: ['cheese'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for multiple languages_filter' do
    expected_filters =
      [
        { term: { languages: 'cheese' } },
        { term: { languages: 'ice cream' } }
      ]
    params = { languages_filter: ['cheese', 'ice cream'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  # literary form is only single value
  test 'build query structure for literary_form_filter' do
    expected_filters =
      [
        { term: { literary_form: 'cheese' } }
      ]
    params = { literary_form_filter: 'cheese' }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for single subjects_filter' do
    expected_filters =
      [
        { term: { 'subjects.value.keyword': 'cheese' } }
      ]
    params = { subjects_filter: ['cheese'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end

  test 'build query structure for multiple subjects_filter' do
    expected_filters =
      [
        { term: { 'subjects.value.keyword': 'cheese' } },
        { term: { 'subjects.value.keyword': 'ice cream' } }
      ]
    params = { subjects_filter: ['cheese', 'ice cream'] }

    assert_equal(expected_filters, FilterBuilder.new.build(params))
  end
end
