# Declaring Azure Storage datasets

``` r

library(azr)
```

A *dataset* is a named, environment-aware pointer to data in Azure
Storage. You declare **where** the data lives once, and then ask `azr`
to build the concrete URI for whichever environment (tier) you are
running in. A *catalog* groups related datasets so they can be stored,
shared, and resolved together.

This separates two concerns that usually get tangled together in
pipeline code:

- the **stable identity** of a dataset (its name, container, path,
  format), and
- the **environment-specific** storage account it currently lives in.

## A single dataset

[`azr_dataset()`](https://pedrobtz.github.io/azr/reference/azr_dataset.md)
declares one dataset. Only the storage account varies by tier — the
container, path, scheme, and format are shared across every environment:

``` r

orders <- azr_dataset(
  name      = "orders",
  scheme    = "abfss",
  container = "raw",
  storage   = list(prod = "stprod001", preprod = "stpreprod001"),
  path      = "sales/orders",
  format    = "delta"
)

orders
```

`name` must match `^[a-z][a-z0-9_]*$` so it can be used as a stable
lookup key, `path` must be non-empty (a dataset cannot point at a
container root), and `format` must be one of `delta`, `parquet`, `csv`,
`tsv`, `json`, `avro`, `orc`, or `text`.

## Building a URI

[`azr_dataset_uri()`](https://pedrobtz.github.io/azr/reference/azr_dataset_uri.md)
turns a dataset into a concrete URI for one tier. The default
`uri_type = "hadoop"` produces the ABFS form used by Spark, Flink,
Trino, and any `hadoop-azure` consumer:

``` r

azr_dataset_uri(orders, tier = "prod")
#> "abfss://raw@stprod001.dfs.core.windows.net/sales/orders"
```

Switch tier to point the same dataset at a different storage account, or
ask for the `https` form:

``` r

azr_dataset_uri(orders, tier = "preprod", uri_type = "https")
#> "https://stpreprod001.dfs.core.windows.net/raw/sales/orders"
```

Requesting a tier the dataset doesn’t declare is an error that lists the
tiers it does have, so misconfiguration fails loudly rather than
silently reading the wrong environment.

### The default tier

`tier` defaults to the `dataset_tier` option, so production code rarely
needs to pass it. Set it once via `options(azr.dataset_tier = ...)` or
the `AZR_DATASET_TIER` environment variable (default `"prod"`) — for
example, a pre-production job can export `AZR_DATASET_TIER=preprod` and
every
[`azr_dataset_uri()`](https://pedrobtz.github.io/azr/reference/azr_dataset_uri.md)
call follows.

## Resolving to a manifest

A URI alone isn’t enough to *load* data — a reader also needs the
format.
[`azr_resolve_dataset()`](https://pedrobtz.github.io/azr/reference/azr_resolve_dataset.md)
returns an `azr_dataset_manifest` carrying the `name`, `uri`, and
`format` together (call [`as.list()`](https://rdrr.io/r/base/list.html)
for a plain R list):

``` r

m <- azr_resolve_dataset(orders, tier = "prod")
m
#> <azr_dataset_manifest:orders>
#> uri: abfss://raw@stprod001.dfs.core.windows.net/sales/orders
#> format: delta
```

This is exactly the shape a reader like `sparklyr::spark_read_source()`
wants:

``` r

m <- azr_resolve_dataset(orders, tier = "prod")
spark_read_source(sc, name = m@name, source = m@format, path = m@uri)
```

## Creating a dataset from a URI

If you already have a full storage URI,
[`azr_dataset_from_uri()`](https://pedrobtz.github.io/azr/reference/azr_dataset_from_uri.md)
parses it into a dataset. The parsed storage account is bound to `tier`;
`name` defaults to the last path segment (with any file extension
removed); and `format` is inferred from the URI’s file extension (or
`_delta_log` segment) when you don’t pass it:

``` r

file <- azr_dataset_from_uri(
  "abfss://raw@stprod001.dfs.core.windows.net/sales/orders/part.parquet",
  name = "orders_file"
)

file
#> <azr_dataset:orders_file>
#> scheme: abfss
#> container: raw
#> path: sales/orders/part.parquet
#> format: parquet
#> storage: prod=stprod001
```

A directory URI has no file extension to infer from, so `format`
defaults to `"delta"`. Pass `format` explicitly to override it (for
example a directory of Parquet files):

``` r

# Directory URI → format defaults to "delta"
azr_dataset_from_uri(
  "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
  name = "orders"
)

# Override the default for a non-delta directory
azr_dataset_from_uri(
  "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
  name   = "orders",
  format = "parquet"
)
```

To make the dataset multi-tier, supply additional accounts via
`storage`:

``` r

azr_dataset_from_uri(
  "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
  name    = "orders",
  format  = "delta",
  tier    = "prod",
  storage = list(preprod = "stpreprod001")
)
```

## Grouping datasets in a catalog

An
[`azr_catalog()`](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
holds an ordered collection of datasets with unique names. It behaves
like a named container: index with `[[`, and use
[`names()`](https://rdrr.io/r/base/names.html) and
[`length()`](https://rdrr.io/r/base/length.html):

``` r

catalog <- azr_catalog(datasets = list(orders, file))

names(catalog)
#> "orders" "orders_file"
length(catalog)
#> 2
catalog[["orders"]]
```

[`azr_dataset_uri()`](https://pedrobtz.github.io/azr/reference/azr_dataset_uri.md)
and
[`azr_resolve_dataset()`](https://pedrobtz.github.io/azr/reference/azr_resolve_dataset.md)
both dispatch on a catalog. With no `name`, they return one entry per
dataset, keyed by name:

``` r

azr_dataset_uri(catalog, tier = "prod")
#> orders      "abfss://raw@stprod001.dfs.core.windows.net/sales/orders"
#> orders_file "abfss://raw@stprod001.dfs.core.windows.net/sales/orders/part.parquet"
```

Pass `name` to resolve a single dataset out of the catalog:

``` r

azr_dataset_uri(catalog, tier = "prod", name = "orders")
azr_resolve_dataset(catalog, tier = "prod", name = "orders")
```

## Storing a catalog as JSON

A catalog round-trips to JSON, so you can keep dataset definitions in
version control and load them at runtime.
[`azr_catalog_write()`](https://pedrobtz.github.io/azr/reference/azr_catalog_write.md)
serialises a catalog and
[`azr_catalog_read()`](https://pedrobtz.github.io/azr/reference/azr_catalog_read.md)
reads it back:

``` r

azr_catalog_write(catalog, "datasets.json")

catalog <- azr_catalog_read("datasets.json")
```

The JSON shape is one object per dataset under a top-level `datasets`
array:

``` json
{
  "datasets": [
    {
      "name": "orders",
      "scheme": "abfss",
      "container": "raw",
      "storage": { "prod": "stprod001", "preprod": "stpreprod001" },
      "path": "sales/orders",
      "format": "delta"
    }
  ]
}
```

[`azr_catalog_read()`](https://pedrobtz.github.io/azr/reference/azr_catalog_read.md)
validates every entry, reporting which dataset (by index and name) is
invalid and why — so a malformed catalog fails at load time rather than
when a pipeline later tries to read a dataset.

## Putting it together

A typical flow: keep a `datasets.json` in the repo, read it into a
catalog, and resolve the dataset you need for the current tier.

``` r

catalog <- azr_catalog_read("datasets.json")

m <- azr_resolve_dataset(catalog, name = "orders")  # tier from AZR_DATASET_TIER
df <- spark_read_source(sc, name = m@name, source = m@format, path = m@uri)
```

The same code runs unchanged in every environment; only the
`dataset_tier` option (or `AZR_DATASET_TIER`) decides which storage
account the URIs point at.
