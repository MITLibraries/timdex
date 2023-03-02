---
layout: home
title: Returning fields in GraphQL
parent: How-to guides
nav_order: 4
---

## Returning specific fields

One of GraphQL's unique features is how it returns fields in query results. When you make a GraphQL query, it does not
return all of the available fields in the results; instead, you include in the query the specific fields you want to
return. This can make it easier to get only the data you're interested in.

For example, in the query below, we are returning the `title` and `contributors` field. `Contributors` is returned a
little differently because it's a nested field, also known as a multivalue field. Here we're requesting the `value`,
but we could also return, for example, the `kind` subfield to see the type of contributor (author, editor, etc).

```graphql
{
  search(searchterm: "afrofuturism") {
    records {
      title
      contributors {
        value
      }
    }
  }
}
```

[Run this query in the GraphQL playground.](https://timdex.mit.edu/playground?query=%7B%0A%20%20search(searchterm%3A%20%22afrofuturism%22)%20%7B%0A%20%20%20%20records%20%7B%0A%20%20%20%20%20%20title%0A%20%20%20%20%20%20contributors%20%7B%0A%20%20%20%20%20%20%20%20value%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D)

Note that you can see in the [GraphQL playground](https://timdex.mit.edu/playground) shows which fields are nested and
what their subfields are. This is also documented in our [API reference](https://mitlibraries.github.io/timdex/reference).

### See also

- [Keyword searching](searching_keywords)
- [Searching specific fields](searching_fields)
