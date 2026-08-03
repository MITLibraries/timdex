# 8. Expose tuning parameters in public GraphQL schema

Date: 2026-07-31

## Status

Accepted

## Context

TIMDEX currently supports internal semantic tuning arguments on the search field:

- semantic_must_boost_threshold
- semantic_drop_boost_threshold
- semantic_short_query_max_tokens

These arguments are accepted at runtime, but are intentionally hidden from GraphQL introspection by custom visibility behavior in the schema.

This creates a mismatch for downstream clients that validate against introspection-derived schema artifacts, including graphql-client. Those clients fail validation because the schema they consume does not include arguments that our internal callers (timdex-ui in particular) need to send.

Our GraphQL API is public, but exposing advanced tuning arguments is acceptable, even if most external users do not need them. These parameters can be in the public schema as they do not do anything harmful or expose hidden data, they just set different threshholds for how we build our queries. Worst case is someone gets less results than they otherwise would if they use them improperly. We can state clearly they are likely not useful to most users in the documentation exposed by the Introspection queries.

We also want a parameter design that allows adding new tuning knobs with minimal schema churn.

## Decision

We will replace the three individual semantic tuning arguments with one public argument on search named tuningParameters.

The new argument will use a typed GraphQL input object (TuningParametersInput).

The resolver will:

- Accept a structured tuningParameters object.
- Rely on GraphQL schema validation for shape and field names.
- Validate value ranges for recognized fields.
- Pass validated values to semantic_options for semantic and hybrid query execution.

Initial recognized keys:

- mustBoostThreshold (Float, 0.0 to 1.0)
- dropBoostThreshold (Float, 0.0 to 1.0)
- shortQueryMaxTokens (Integer, greater than 0)

Note: graphql-ruby will expose camelCase in schema while resolver keyword arguments can remain idiomatic Ruby.

We will also remove the introspection-hiding behavior for INTERNAL USE ONLY arguments because hidden runtime behavior is incompatible with schema-validating clients.

## Options considered

### Option A: Keep three individual arguments and stop hiding them

Example shape:

search(
 searchterm: String,
 semanticMustBoostThreshold: Float,
 semanticDropBoostThreshold: Float,
 semanticShortQueryMaxTokens: Int
)

Example query:

query {
 search(
  searchterm: "data analytics"
  semanticMustBoostThreshold: 0.9
  semanticDropBoostThreshold: 0.1
  semanticShortQueryMaxTokens: 10
 ) {
  hits
 }
}

Pros:

- Minimal implementation change.
- Strong GraphQL typing.
- Fully compatible with schema validation.

Cons:

- Schema must be updated whenever a new tuning knob is added.
- Search field argument list grows over time.

### Option B: Single input object argument (chosen)

Example shape:

input TuningParametersInput {
 mustBoostThreshold: Float
 dropBoostThreshold: Float
 shortQueryMaxTokens: Int
}

search(searchterm: String, tuningParameters: TuningParametersInput)

Example query:

query {
 search(
  searchterm: "data analytics"
  tuningParameters: {
   mustBoostThreshold: 0.9
   dropBoostThreshold: 0.1
   shortQueryMaxTokens: 10
  }
 ) {
  hits
 }
}

Pros:

- Cleaner schema than many top-level arguments.
- Strong typing and introspection docs.
- Backward compatible when adding optional fields.

Cons:

- Clients must update schema artifacts before using newly added fields.
- Unknown fields are rejected during GraphQL validation.

### Option C: Single JSON argument (strong candidate)

Example shape:

search(searchterm: String, tuningParameters: JSON)

Example query:

query {
 search(
  searchterm: "data analytics"
  tuningParameters: {
   must_boost_threshold: 0.9
   drop_boost_threshold: 0.1
   short_query_max_tokens: 10
  }
 ) {
  hits
 }
}

Example future extension without schema changes:

query {
 search(
  searchterm: "data analytics"
  tuningParameters: {
   must_boost_threshold: 0.9
   short_query_max_tokens: 10
   future_new_parameter: 42
  }
 ) {
  hits
 }
}

Pros:

- Easy to add new tuning keys without changing GraphQL schema shape.
- Avoids frequent schema coordination for internal tuning evolution.
- Keeps one simple top-level argument.
- Allows "hidden" tuning parameters we don't want to expose in documentation.

Cons:

- Weaker static typing at GraphQL boundary.
- Validation shifts to resolver code.
- Harder for consumers to discover valid keys without documentation.

## Consequences

Documentation note:

Ensure schema descriptions for tuningParameters and its input fields clearly explain purpose, safe ranges, and that these are advanced options not recommended for most users.

Positive:

- Resolves graphql-client schema validation mismatch.
- Keeps a clean, typed contract for advanced users.
- Keeps public API behavior explicit and introspectable.

Trade-offs:

- Adding new tuning fields still requires schema updates and refreshed client schema artifacts.
- Requires range validation tests for semantic thresholds and token limits.
- If we want tuning knobs in the future that we aren't comfortable making public, we would need to consider another input object closer to Option C

## Implementation Plan

Tips:

- Add test coverage for accepted and invalid tuning values.
- Document currently supported tuning fields in internal runbooks and public docs as advanced parameters.
- Add a short note in docs that these are advanced options and not generally recommended for most clients.

1. Add tuningParameters input object argument to search.
2. Map validated tuning values into semantic_options payload used by semantic and hybrid query builders.
3. Remove schema visibility override that hides INTERNAL USE ONLY arguments during introspection.
4. Update tests that currently assert hidden introspection arguments.
5. Add tests for tuningParameters validation and passthrough behavior.
6. Update docs and internal examples.
