require 'test_helper'

class RecordTypeTest < ActiveSupport::TestCase
  # Test that file_formats handles missing key gracefully
  test 'file_formats returns nil when file_formats key is missing' do
    record_data = { 'title' => 'Test Record' }
    record_type = Types::RecordType.send(:new, record_data, {})

    result = record_type.file_formats
    assert_nil result, 'file_formats should return nil when key is missing'
  end

  # Test that file_formats handles explicit nil gracefully
  test 'file_formats returns nil when file_formats is nil' do
    record_data = { 'title' => 'Test Record', 'file_formats' => nil }
    record_type = Types::RecordType.send(:new, record_data, {})

    result = record_type.file_formats
    assert_nil result, 'file_formats should return nil when value is nil'
  end

  # Test that file_formats works correctly when data is present
  test 'file_formats returns unique formats when present' do
    record_data = {
      'title' => 'Test Record',
      'file_formats' => %w[PDF PDF EPUB PDF]
    }
    record_type = Types::RecordType.send(:new, record_data, {})

    result = record_type.file_formats
    assert_equal %w[PDF EPUB], result, 'file_formats should return unique values'
  end
end
