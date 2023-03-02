---
layout: home
title: Viewing aggregations
parent: How-to guides
nav_order: 6
---

## Viewing search aggregations

Aggregations list the total count of search results meeting a certain criterion. For example, you may want to know how
many results of a query are in a certain language; aggregations will provide this data as part of the results.

You can review [our reference documentation for the Aggregations type](../reference/#definition-Aggregations) to see all
aggregations provided by TIMDEX. In the example below, we will use the `source` aggregation to see how records matching
the search term "modal jazz" are distributed across sources.


```graphql
{
  search(searchterm: "modal jazz") {
    records {
      source
      sourceLink
      title
    }
    aggregations {
      source {
        docCount
        key
      }
    }
  }
}
```

[Run this query in the GraphQL playground.](https://timdex.mit.edu/playground?query=%7B%0A%20%20search(searchterm%3A%20%22modal%20jazz%22)%20%7B%0A%20%20%20%20records%20%7B%0A%20%20%20%20%20%20source%0A%20%20%20%20%20%20sourceLink%0A%20%20%20%20%20%20title%0A%20%20%20%20%7D%0A%20%20%20%20aggregations%20%7B%0A%20%20%20%20%20%20source%20%7B%0A%20%20%20%20%20%20%20%20docCount%0A%20%20%20%20%20%20%20%20key%0A%20%20%20%20%20%20%7D%0A%20%20%09%7D%0A%20%20%7D%0A%7D)


Note that all aggregations are multivalue fields that require the `docCount` and `key` subfields.

## See also

- [Using filters to narrow your search](using_filters)
