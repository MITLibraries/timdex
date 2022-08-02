# Targeting specific fields with your search

In addition to [keyword searches](keyword-searching), it is possible to search a specific field. Try using the query
below in our [GraphQL playground](https://timdex.mit.edu/playground):


```graphql
{
  search(title: "Indigenous art") {
    records {
      title
      contributors {
        value
      }
    }
  }
}
```

This query will search for records with "Indigenous art" in the title and return the 'title' and 'contributor' fields
of the matching results. (Note that 'contributors' is returned differently than 'title'. Check our guide on [returning
fields](returning-fields-in-graphql) for more information on this.)


You can also query multiple fields in the same search:

```graphql
{
  search(title: "Indigenous art", subjects: "architecture") {
    records {
      title
      contributors {
        value
      }
    }
  }
}
```

This query is similar to the first, except our results will include only records with 'Indigenous art' in the 'title'
field and 'architecture' in the 'subjects' field.

## See also

- [Keyword searching](keyword-searching)
- [Returning fields in GraphQL](returning-fields-in-graphql)
