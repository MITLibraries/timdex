# Highlighting search terms in results

TIMDEX can return a list of search term matches in the results. The field that returns these matches is called
'highlight':

```graphql
{
  search(searchterm: "data") {
    records {
      highlight {
        matchedField
        matchedPhrases
      }
    }
  }
}
```

In the query above will return a list of matches for the search term 'data'. The 'highlight' field is nested; subfield
'matchedField' will show the field that matched your search term, and subfield 'matchedPhrases' will show where in the
field the search term was matched.

Here's an example of a result:

```json
{
  "highlight": [
    {
      "matchedField": "citation",
      "matchedPhrases": [
        "<span class=\"highlight\">Data</span> security and <span class=\"highlight\">data</span> processing. 1975."
      ]
    },
    {
      "matchedField": "title",
      "matchedPhrases": [
        "<span class=\"highlight\">Data</span> security and <span class=\"highlight\">data</span> processing"
      ]
    }
  ]
}
```

In this case, we found matches in the 'citation' and 'title' fields. The HTML included in the 'matchedPhrases' subfield
is for display purposes. If you plan to display the TIMDEX data in a user interface, you can write a CSS rule on the
'highlight' class to emphasize the text however you choose.

While the example above shows the entire fields, 'matchedPhrases' has a character limit. If the field contains more
than 100 characters, TIMDEX will return a 100-character fragment that contains the highlighted term.

## See also

- [Returning fields in GraphQL](returning-fields-in-graphql)
