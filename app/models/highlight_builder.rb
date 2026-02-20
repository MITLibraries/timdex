class HighlightBuilder
  def build
    {
      pre_tags: [
        '<span class="highlight">'
      ],
      post_tags: [
        '</span>'
      ],
      fields: {
        '*': {}
      }
    }
  end
end
