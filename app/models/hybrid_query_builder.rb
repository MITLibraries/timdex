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
    rescue StandardError => e
      # Semantic builder failed (Lambda error, etc.) - use lexical only
      log_semantic_error(e)
      raise unless semantic_fallback_error?(e)

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
        normalize_keys(semantic_query),
        lexical_search
      ]
    }

    # Apply only filters (non-q constraints) at top level so they apply to both branches
    hybrid_bool[:filter] = top_level_filters if top_level_filters.present?

    # When filters are present, require at least one of the semantic/lexical branches
    # to match so the query does not degrade into a filter-only match
    hybrid_bool[:minimum_should_match] = 1 if top_level_filters.present?

    {
      bool: hybrid_bool
    }
  end

  # Logs semantic query builder failures for observability
  def log_semantic_error(error)
    return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

    Rails.logger.warn(
      "HybridQueryBuilder semantic query failed: #{error.class}: #{error.message}"
    )
  end

  # Only fall back to lexical for Lambda/invocation errors from SemanticQueryBuilder.
  # All other errors (parsing, validation, unexpected bugs) should be re-raised.
  def semantic_fallback_error?(error)
    error.is_a?(SemanticQueryBuilder::LambdaError)
  end

  # Recursively converts all string keys to symbols in hashes and nested structures.
  # This ensures consistency since semantic builder returns string keys while lexical uses symbols.
  def normalize_keys(value)
    case value
    when Hash
      value.transform_keys { |k| k.is_a?(String) ? k.to_sym : k }
           .transform_values { |v| normalize_keys(v) }
    when Array
      value.map { |item| normalize_keys(item) }
    else
      value
    end
  end
end
