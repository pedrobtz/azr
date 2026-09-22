# Azure Storage dataset

An S7 class representing an Azure Storage dataset bound to one or more
storage accounts keyed by environment tier (e.g. `"prod"`, `"preprod"`).

## Usage

``` r
azr_dataset(
  name = character(0),
  scheme = character(0),
  container = character(0),
  storage = list(),
  path = character(0),
  format = character(0),
  endpoint_suffix = "core.windows.net"
)
```

## Arguments

- name:

  Dataset name. Must match `^[a-z][a-z0-9_]*$`.

- scheme:

  Hadoop filesystem scheme: `"abfss"` or `"wasbs"`.

- container:

  Container (filesystem) name.

- storage:

  Non-empty named list mapping tier name to storage account.

- path:

  Path within the container, without leading or trailing `/`.

- format:

  Dataset format: `"delta"`, `"parquet"`, `"csv"`, `"tsv"`, `"json"`,
  `"avro"`, `"orc"`, or `"text"`.

- endpoint_suffix:

  Storage endpoint suffix. Defaults to `"core.windows.net"`.

## Value

An `azr_dataset` S7 object.

## Details

Only the storage account varies by tier: `container`, `path`,
`endpoint_suffix`, and `scheme` are shared across all tiers in
`storage`. If an environment also needs a different container, path, or
sovereign cloud, model it as a separate azr_dataset.

`path` must be non-empty, so a dataset cannot point at a container root.
