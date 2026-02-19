class FilterBuilder
  def build(params)
    f = []

    if params[:contributors_filter].present?
      params[:contributors_filter].each do |p|
        f.push filter_field_by_value('contributors.value.keyword', p)
      end
    end

    if params[:content_type_filter].present?
      params[:content_type_filter].each do |p|
        f.push filter_field_by_value('content_type', p)
      end
    end

    if params[:content_format_filter].present?
      params[:content_format_filter].each do |p|
        f.push filter_field_by_value('format', p)
      end
    end

    if params[:languages_filter].present?
      params[:languages_filter].each do |p|
        f.push filter_field_by_value('languages', p)
      end
    end

    # literary_form is a single value aggregation
    if params[:literary_form_filter].present?
      f.push filter_field_by_value('literary_form',
                                   params[:literary_form_filter])
    end

    # places are really just a subset of subjects so the filter uses the subject field
    if params[:places_filter].present?
      params[:places_filter].each do |p|
        f.push filter_field_by_value('subjects.value.keyword', p)
      end
    end

    # source aggregation is "OR" and not "AND" so it does not use the filter_field_by_value method
    f.push filter_sources(params[:source_filter]) if params[:source_filter]

    # access to files aggregation is "OR" and not "AND" so it does not use the filter_field_by_value method
    f.push filter_access_to_files(params[:access_to_files_filter]) if params[:access_to_files_filter]

    if params[:subjects_filter].present?
      params[:subjects_filter].each do |p|
        f.push filter_field_by_value('subjects.value.keyword', p)
      end
    end

    f
  end

  def filter_field_by_value(field, value)
    {
      term: { "#{field}": value }
    }
  end

  # multiple access to files values are ORd
  def filter_access_to_files(param)
    { nested: {
      path: 'rights',
      query: {
        bool: {
          should: access_to_files_array(param)
        }
      }
    } }
  end

  def access_to_files_array(param)
    rights = []
    param.each do |right|
      rights << {
        term: {
          'rights.description.keyword': right
        }
      }
    end
    rights
  end

  # multiple sources values are ORd
  def filter_sources(param)
    {
      bool: {
        should: source_array(param)
      }
    }
  end

  def source_array(param)
    sources = []
    param.each do |source|
      sources << {
        term: {
          source:
        }
      }
    end
    sources
  end
end
