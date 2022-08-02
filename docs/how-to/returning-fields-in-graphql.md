# Returning fields in GraphQL

One of GraphQL's unique features is how it returns fields in query results. When you make a GraphQL query, it does not
return all of the available fields in the results; instead, you include in the query the specific fields you want to
return. This can make it easier to get only the data you're interested in.

For example, in the query below, we are returning the 'title' and 'contributors' field. 'Contributors' is returned a
little differently because it's a nested field, and we're requesting the 'value' subfield.

```graphql
{
  search(searchterm: "data") {
    records {
      title
      contributors {
        value
      }
    }
  }
}
```

You can test out this and other queries in our [GraphQL playground](https://timdex.mit.edu/playground). While you're
there, check out the 'schema' tab to see which fields are nested and what their subfields are.

## See also

- [Keyword searching](keyword-searching)
- [Searching specific fields](searching-specific-fields)
