# Read a dataset catalog from JSON

Reads a JSON file describing a collection of datasets and returns an
[azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md).

The expected JSON shape:


    {
      "datasets": [
        {
          "name": "sales_orders",
          "scheme": "abfss",
          "container": "raw",
          "storage": { "prod": "stprod001", "preprod": "stpreprod001" },
          "path": "sales/orders",
          "format": "delta"
        }
      ]
    }

## Usage

``` r
azr_catalog_read(json_file)
```

## Arguments

- json_file:

  Path to a JSON file.

## Value

An
[azr_catalog](https://pedrobtz.github.io/azr/reference/azr_catalog.md)
object.

## See also

[`azr_catalog_write()`](https://pedrobtz.github.io/azr/reference/azr_catalog_write.md)
