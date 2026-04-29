class HybridQueryBuilder
  def build(params, fulltext: false)
    query_text = params[:q].to_s.strip

    lexical_query = LexicalQueryBuilder.new.build(params, fulltext: fulltext)

    # If no query text provided, return lexical query so filters/other constraints are still applied
    return lexical_query if query_text.blank?

    begin
      semantic_query = SemanticQueryBuilder.new.build(params, fulltext: fulltext)

      # Both succeeded - combine them with should clause while preserving filters
      combine_queries(semantic_query, lexical_query)
    rescue SemanticQueryBuilder::LambdaError => e
      # Lambda service failure - report to Sentry and gracefully fall back to lexical search
      Sentry.capture_exception(e, level: 'warning')
      Rails.logger.warn(
        "HybridQueryBuilder semantic query failed: #{e.class}: #{e.message}"
      )
      lexical_query
    end
  end

  private

  # Combines semantic and lexical queries while preserving non-q filters.
  # The q multi_match stays in the lexical branch to allow semantic-only matches.
  def combine_queries(semantic_query, lexical_query)
    # Extract filters (non-q constraints like title/citation/geo) to apply at top level.
    # Do NOT extract must (which contains the q multi_match) - it stays in lexical branch
    # so semantic matches can be returned without matching the q query.
    lexical_bool = lexical_query.is_a?(Hash) && lexical_query[:bool] ? lexical_query[:bool] : {}
    top_level_filters = lexical_bool[:filter] || []

    # Keep the full lexical query structure (with q multi_match in must) but remove filters
    # so we don't duplicate them in the final query
    lexical_search = if lexical_query.is_a?(Hash) && lexical_query[:bool]
                       {
                         bool: {
                           should: lexical_bool[:should] || [],
                           must: lexical_bool[:must] || []
                         }.reject { |_, v| v.blank? }
                       }
                     else
                       lexical_query
                     end

    hybrid_bool = {
      should: [
        semantic_query,
        lexical_search
      ]
    }

    # Apply only filters (non-q constraints) at top level so they apply to both branches
    hybrid_bool[:filter] = top_level_filters if top_level_filters.present?

    # In OpenSearch, when a bool query has no filters, should clauses are required by default.
    # When filters are added, should clauses become optional. We explicitly require at least
    # one should clause to match (semantic or lexical) when filters are present, so we don't
    # return filter-only results that matched neither branch.
    hybrid_bool[:minimum_should_match] = 1 if top_level_filters.present?

    {
      bool: hybrid_bool
    }
  end
end
