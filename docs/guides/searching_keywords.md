---
layout: home
title: Keyword searching
parent: How-to guides
nav_order: 1
---

## Keyword searching

To search via keyword, provide a value to the `searchterm`, such as `searchterm: "my amazing keyword search"`.

GraphQL requires you to specify which fields to return. In this example, we'll request the `title`, `source`,
`sourceLink`, and `summary` fields.

Our [GraphQL Playground](https://timdex.mit.edu/playground) provides documentation on the fields, and will make
suggestions and inform you of syntax errors as you write your queries. Because of this, it is often a useful place to
develop queries prior to copying them into any scripts or applications you are writing.

```graphql
{
  search(searchterm: "orbital velocity") {
    records {
      title
      source
      sourceLink
      summary
    }
  }
}
```

[Run this query in the GraphQL playground.](https://timdex.mit.edu/playground?query=%7B%0A%20%20search(searchterm%3A%20%22orbital%20velocity%22)%20%7B%0A%20%20%20%20records%20%7B%0A%20%20%20%20%20%20title%0A%20%20%20%20%20%20source%0A%20%20%20%20%20%20sourceLink%0A%20%20%20%20%20%20summary%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D)

### See also

- [Limiting your search to specified sources](using_filters)
- [Returning fields in GraphQL](returning_fields)
- [Retrieving a single record](retrieving_records)
