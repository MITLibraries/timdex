class SortBuilder
  def build
    [
      { _score: { order: 'desc' } },
      {
        'dates.value.as_date': {
          order: 'desc',
          nested: {
            path: 'dates'
          }
        }
      }
    ]
  end
end
