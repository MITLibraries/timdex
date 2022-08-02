# Limiting your search to specified source(s)

This example demonstrates a query that searches for the term "data" in the two sources `dspace@mit` and `zenodo`. We are
requesting the fields `source`, `sourceLink` and `title` be returned for each found record.

You can copy this query into our GraphQL playground or your preferred GraphQL client to see it in action!

```graphql
{
  search(searchterm: "data", sourceFacet: ["dspace@mit", "zenodo"]) {
    records {
      source
      sourceLink
      title
    }
  }
}
```

## See also

- [Keyword searching](keyword-searching)
- [Which sources are available to search](../reference/which-sources-are-available-to-search)
