# Consolidate Azure storage interfaces

## Summary

Use composition around one internal storage core. Keep the existing R6 facade
classes only for compatibility:

- `azure_storage()` returns an object exposing `$table()`.
- `get_moniker()` and `get_aks_moniker()` return objects exposing `$read()`.
- Resolution and backend execution become independent strategies shared by both
  facades.

## Key changes

### Internal architecture

- Introduce one internal `StorageCore` responsible for:
  1. Resolving a dataset name into a locator.
  2. Passing that locator to the selected backend.
  3. Adding consistent validation and error context.
- Make the existing R6 classes thin facades holding a private `StorageCore`.
- Prefer composition over backend subclasses. Backend and resolver strategies
  may be lightweight closures or lists unless they need lifecycle state.

Define one internal locator shape containing `name`, `tier`, optional `id`,
optional `uri`, and format metadata.

### Resolution strategies

- **Catalog resolver:** reads the direct-URL catalog used by `azure_storage()`
  and selects the URL for the requested environment.
- **Bindings resolver:** loads `name -> id` bindings, calls the REST API with
  `(id, tier)`, and caches the resulting URL by `(name, tier)` for the
  connection lifetime.
- **Native resolver:** returns the logical name unchanged for real Moniker,
  allowing its JVM implementation to perform binding and REST resolution
  internally.

Unknown datasets, missing tiers, and REST failures must be reported before
backend invocation, including dataset name, identifier when known, and tier.

### Backend strategies

- **DuckDB:** requires a resolved URI and performs the existing DuckDB Delta
  read.
- **Spark:** requires a resolved URI and performs `sparklyr::read_delta()` or
  its current equivalent.
- **Moniker:** consumes the logical dataset name and delegates to the additional
  JVM jars. It must not call the R REST resolver.

All backend-specific connection options remain inside `args`; they must not
leak into resolver configuration.

## Public interfaces

- Preserve `azure_storage(catalog, env = "prod", ...)`.
- Add `backend = c("duckdb", "spark")`, defaulting to `"duckdb"`.
- Preserve `$table(name, ...)` as its only dataset-reading method.
- Preserve
  `get_moniker(bindings = "bindings.json", env = "prod", args = list(...))`.
- Implement `get_moniker()` as the Spark backend plus the bindings REST
  resolver.
- Preserve `get_aks_moniker(args = list(...))`.
- Implement `get_aks_moniker()` as the native Moniker backend plus the native
  resolver; `bindings` and `env` remain in `args`.
- Preserve existing R6 class names and inheritance contracts. The facade
  methods delegate to `private$core$read_dataset()`.

Do not expose `$read()` on `azure_storage()` objects or `$table()` on Moniker
objects.

## Migration

1. Add characterization tests around existing constructors, R6 identities,
   argument forwarding, and return values.
2. Introduce the locator, resolvers, backend strategies, and `StorageCore`.
3. Rewire each public constructor to assemble the appropriate resolver/backend
   combination.
4. Move `$table()` and `$read()` implementations to one-line facade
   delegations.
5. Remove duplicated resolution and read logic from legacy backend classes,
   then delete backend classes that no longer hold meaningful behavior.

## Test plan

- `azure_storage()` defaults to DuckDB and `$table()` reads a direct catalog
  URI.
- `azure_storage(backend = "spark")` resolves the same catalog entry and
  invokes Spark.
- `get_moniker()` performs `name -> id -> URI`, invokes Spark, and exposes only
  `$read()`.
- Repeated `get_moniker()` reads cache REST resolution per dataset and tier.
- `get_aks_moniker()` passes the dataset name to the JVM backend without
  calling the R resolver.
- Existing R6 class identity and inheritance checks remain valid.
- Backend arguments reach only the selected backend.
- Unknown names, tiers, unsupported backends, malformed resolver responses,
  and backend failures produce contextual errors.
- No write API or write behavior is added in this refactor.

## Assumptions

- REST-resolved URLs remain valid for the lifetime of a connection.
- Direct-URL catalogs and binding catalogs remain distinct input formats.
- Native Moniker resolution must remain inside the JVM implementation.
- Reading is the canonical internal operation; `$table()` and `$read()` are
  compatibility facade names.
