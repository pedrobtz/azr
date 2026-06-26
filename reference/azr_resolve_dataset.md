# Build a URI + format manifest for an `azr_dataset` or `azr_catalog`

Like
[`azr_dataset_uri()`](https://pedrobtz.github.io/azr/reference/azr_dataset_uri.md),
but each entry also carries the dataset's `format`, which together are
what a reader (e.g. `sparklyr::spark_read_source()`) needs to load a
dataset.

## Usage

``` r
azr_resolve_dataset(x, ...)
```

## Arguments

- x:

  An
  [azr_dataset](https://pedrobtz.github.io/azr/reference/azr_dataset.md)
  or
  [azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
  object.

- ...:

  Additional arguments passed to methods:

  `tier`

  :   Environment tier name (a key in the dataset's `storage`). Defaults
      to the `dataset_tier` option (`options(azr.dataset_tier = ...)` or
      `AZR_DATASET_TIER`, default `"prod"`); see
      [`azr_options()`](https://pedrobtz.github.io/azr/reference/azr_options.md).

  `uri_type`

  :   URI type: `"https"` or `"hadoop"` (the Hadoop ABFS URI form
      `scheme://container@account.dfs.../path`, used by Spark, Flink,
      Trino, and any `hadoop-azure` consumer).

  `name`

  :   For an
      [azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
      only: an optional character scalar selecting a single dataset by
      name. If omitted, URIs for every dataset are returned.

## Value

For an
[azr_dataset](https://pedrobtz.github.io/azr/reference/azr_dataset.md),
or an
[azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
with `name` supplied, an
[azr_dataset_manifest](https://pedrobtz.github.io/azr/reference/azr_dataset_manifest.md).
For an
[azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
without `name`, a named list of `azr_dataset_manifest` objects, keyed by
dataset name.

## Examples

``` r
ds <- azr_dataset(
  name = "orders",
  scheme = "abfss",
  container = "raw",
  storage = list(prod = "stprod001"),
  path = "sales/orders",
  format = "delta"
)
azr_resolve_dataset(ds, tier = "prod")
#> <azr_dataset_manifest:orders>
#> uri: abfss://raw@stprod001.dfs.core.windows.net/sales/orders
#> format: delta

catalog <- azr_catalog(datasets = list(ds))
azr_resolve_dataset(catalog, tier = "prod")
#> $orders
#> <azr_dataset_manifest:orders>
#> uri: abfss://raw@stprod001.dfs.core.windows.net/sales/orders
#> format: delta
#> 
```
