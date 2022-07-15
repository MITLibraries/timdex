# Keyword searching

To search via keyword, you provide a value to the `searchterm`, such as `searchterm: "my amazing keyword search"`.

In GraphQL, you always need to specify which fields to return. In this example, we'll request the `title`, `source`, `sourceLink`, and `summary` fields.

If you use our [GraphQL Playground](../tutorials/using-the-graphql-playground.md), it provides documentation of the fields and will also suggest fields and inform you of syntax errors as you are developing your queries. Because of this, it is often a usefull place to develop queries prior to copying them into any scripts or applications you are writing.

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

## See Also

- [Limiting your search to specified sources](limiting-your-search-to-specified-sources.md)
- [Which sources are available to search](../reference/which-sources-are-available-to-search.md)
- [Tutorial: Using the GraphQL Playground](../tutorials/using-the-graphql-playground.md)
