---
layout: home
title: Using filters to narrow your search
parent: How-to guides
nav_order: 5
---

## Using filters to narrow your search

TIMDEX includes a set of filters that you can use to limit your search. The [API reference](https://mitlibraries.github.io/timdex/reference/#query-search)
for the search operation lists each available filter and how to use them. In this how-guide, we'll look at the
sourceFilter, but the process is similar with other filters. If you're not sure what values a filter will accept, try
a search that [returns aggregations](viewing_aggregations).

This example demonstrates a query that searches for the term "data" in the "dspace@mit" or the "abdul latif jameel
poverty action lab dataverse" sources. We are requesting the fields `source`, `sourceLink` and `title`, which will be
returned for each found record.

```graphql
{
  search(searchterm: "data", sourceFilter: ["dspace@mit", "mit alma"]) {
    records {
      source
      sourceLink
      title
    }
  }
}
```

https://timdex.mit.edu/playground?query=%7B%0A%20%20search(searchterm%3A%20%22data%22%2C%20sourceFilter%3A%20%5B%22dspace%40mit%22%2C%20%22mit%20alma%22%5D)%20%7B%0A%20%20%20%20records%20%7B%0A%20%20%20%20%20%20source%0A%20%20%20%20%20%20sourceLink%0A%20%20%20%20%20%20title%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D

## See also

- [Viewing search aggregations](viewing_aggregations)
