class HybridQueryBuilder
  def build(params, fulltext: false)
    query_text = params[:q].to_s.strip

    # If no query text provided, return a match_all query (consistent with keyword search behavior)
    return { match_all: {} } if query_text.blank?

    lexical_query = LexicalQueryBuilder.new.build(params, fulltext: fulltext)

    begin
      semantic_query = SemanticQueryBuilder.new.build(params, fulltext: fulltext)

      # Both succeeded - combine them with should clause.
      {
        bool: {
          should: [
            normalize_keys(semantic_query),
            lexical_query
          ]
        }
      }
    rescue StandardError
      # Semantic builder failed (Lambda error, etc.) - use lexical only.
      lexical_query
    end
  end

  private

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
