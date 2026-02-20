class SourceBuilder
  def build
    # If ENV OPENSEARCH_SOURCE_EXCLUDES is set, use the values in its comma-separated list;
    # otherwise return nil (which means _source attribute is omitted, returning all fields)
    # excludes are used to prevent large fields from being returned in the search results,
    # which can cause performance issues. These fields are still searchable, just not
    # returned in the search results.
    return unless ENV['OPENSEARCH_SOURCE_EXCLUDES'].present?

    {
      excludes: ENV['OPENSEARCH_SOURCE_EXCLUDES'].split(',').map(&:strip)
    }
  end
end
