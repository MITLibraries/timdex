---
layout: home
title: Retrieving a single record
parent: How-to guides
nav_order: 3
---

## Retrieving a single record


In addition to searching, it is also possible to retrieve a specific record. To do so, you will need the
`timdexRecordId` for the item. You can find this by returning that field in a query, like so:

```graphql
{
  search(searchterm: "pragmatic programmer") {
    records {
      title
      timdexRecordId
    }
  }
}

```

[Run this query in the GraphQL playground.](https://timdex.mit.edu/playground?query=%7B%0A%20%20search(searchterm%3A%20%22pragmatic%20programmer%22)%20%7B%0A%20%20%20%20records%20%7B%0A%20%20%20%20%20%20title%0A%20%20%20%20%20%20timdexRecordId%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D%0A)

Once you have the `timdexRecordId` of the record in question, you can retrieve information about that record only:

```graphql
{
  recordId(id: "alma:9935059777706761") {
    title
    edition
    citation
    holdings {
      location
    }
    identifiers {
      kind
      value
    }
  }
}
```

[Run this query in the GraphQL playground.](https://timdex.mit.edu/playground?query=%7B%0A%20%20recordId(id%3A%20%22alma%3A9935059777706761%22)%20%7B%0A%20%20%20%20title%0A%20%20%20%20edition%0A%20%20%20%20citation%0A%20%20%20%20holdings%20%7B%0A%20%20%20%20%20%20location%0A%20%20%20%20%7D%0A%20%20%20%20identifiers%20%7B%0A%20%20%20%20%20%20kind%0A%20%20%20%20%20%20value%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D)

These are just a few of the fields that you can query on a record. Check out the [reference docs for the `Record` type
for a full list](https://mitlibraries.github.io/timdex/reference/#definition-Record). Note that all of these fields can
also be requested in the `records` field of the `Search` type.

### See also
- [Searching specific fields](searching_fields)
- [Returning specific fields](returning_fields)
