# Build a URI for an `azr_dataset` or look one up in an `azr_catalog`

Build a URI for an `azr_dataset` or look one up in an `azr_catalog`

## Usage

``` r
azr_dataset_uri(x, ...)
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
with `name` supplied, a character scalar URI. For an
[azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
without `name`, a named character vector of URIs keyed by dataset name.

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
azr_dataset_uri(ds, tier = "prod")
#> [1] "abfss://raw@stprod001.dfs.core.windows.net/sales/orders"

catalog <- azr_catalog(datasets = list(ds))
azr_dataset_uri(catalog, tier = "prod", name = "orders")
#> [1] "abfss://raw@stprod001.dfs.core.windows.net/sales/orders"
azr_dataset_uri(catalog, tier = "prod")
#>                                                    orders 
#> "abfss://raw@stprod001.dfs.core.windows.net/sales/orders" 
```
