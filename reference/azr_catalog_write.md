# Write a dataset catalog to JSON

Writes an
[azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
to a JSON file in the shape expected by
[`azr_catalog_read()`](https://pedrobtz.github.io/azr/reference/azr_catalog_read.md).

## Usage

``` r
azr_catalog_write(catalog, json_file)
```

## Arguments

- catalog:

  An
  [azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
  object.

- json_file:

  Path to write the JSON file to.

## Value

`json_file`, invisibly.

## See also

[`azr_catalog_read()`](https://pedrobtz.github.io/azr/reference/azr_catalog_read.md)
