---
layout: home
title: Targeting specific fields with your search
parent: How-to guides
nav_order: 2
---

## Targeting specific fields with your search

In addition to [keyword searches](searching_keywords), it is possible to search a specific field. Try using the query
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

This query will search for records with "Indigenous art" in the title and return the `title` and `contributor` fields
of the matching results. (Note that the multivalue `contributors` field is returned differently than `title`. Check our
guide on [returning fields](returning_fields_in_graphql) for more information on this.)


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

[Run this query in the GraphQL playground.](https://timdex.mit.edu/playground?query=%7B%0A%20%20search(title%3A%20%22Indigenous%20art%22%2C%20subjects%3A%20%22architecture%22)%20%7B%0A%20%20%20%20records%20%7B%0A%20%20%20%20%20%20title%0A%20%20%20%20%20%20contributors%20%7B%0A%20%20%20%20%20%20%20%20value%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D)

This query is similar to the first, except our results will include only records with 'Indigenous art' in the `title`
field and 'architecture' in the `subjects` field.

### See also

- [Keyword searching](searching_keywords)
- [Returning specific fields](returning_fields)
