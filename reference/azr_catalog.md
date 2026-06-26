# Azure Storage dataset catalog

An S7 class holding an ordered collection of
[azr_dataset](https://pedrobtz.github.io/azr/reference/azr_dataset.md)
objects with unique `name`s.

A catalog can be indexed by dataset name with `[[`, and supports
[`names()`](https://rdrr.io/r/base/names.html) and
[`length()`](https://rdrr.io/r/base/length.html).

## Usage

``` r
azr_catalog(datasets = list())
```

## Arguments

- datasets:

  A list of
  [azr_dataset](https://pedrobtz.github.io/azr/reference/azr_dataset.md)
  objects.

## Value

An `azr_catalog` S7 object.

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
catalog <- azr_catalog(datasets = list(ds))

catalog[["orders"]]
#> <azr_dataset:orders>
#> scheme: abfss
#> container: raw
#> path: sales/orders
#> format: delta
#> storage: prod=stprod001
names(catalog)
#> [1] "orders"
length(catalog)
#> [1] 1
```
