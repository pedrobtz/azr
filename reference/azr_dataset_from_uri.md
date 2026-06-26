# Create an `azr_dataset` from a full Azure Storage URI

Parses an Azure Storage URI using
[`parse_storage_path()`](https://pedrobtz.github.io/azr/reference/parse_storage_path.md)
and constructs an
[azr_dataset](https://pedrobtz.github.io/azr/reference/azr_dataset.md).
The parsed storage account is bound to `tier` in `storage`.

## Usage

``` r
azr_dataset_from_uri(
  uri,
  name = NULL,
  format = NULL,
  tier = opts$get("dataset_tier"),
  storage = NULL
)
```

## Arguments

- uri:

  Full Azure Storage URI, such as
  `abfss://raw@account.dfs.core.windows.net/path` or
  `https://account.dfs.core.windows.net/raw/path`.

- name:

  Dataset name. If `NULL` (the default), derived from the last segment
  of the URI's path with any file extension removed, e.g. `"orders"` for
  `.../sales/orders` or `.../sales/orders.parquet`.

- format:

  Dataset format. If `NULL`, inferred from the URI's file extension
  (e.g. `.parquet`, `.csv`) or `_delta_log` segment. Defaults to
  `"delta"` when `uri` looks like a directory. Errors only when `uri`
  has a file extension that maps to no known format; pass `format`
  explicitly then.

- tier:

  Environment tier for the storage account parsed from `uri`. Defaults
  to the `dataset_tier` option (`options(azr.dataset_tier = ...)` or
  `AZR_DATASET_TIER`, default `"prod"`); see
  [`azr_options()`](https://pedrobtz.github.io/azr/reference/azr_options.md).

- storage:

  Optional named list mapping additional tiers to storage accounts. The
  account from `uri` is bound to `tier` unless that key is already
  present.

## Value

An
[azr_dataset](https://pedrobtz.github.io/azr/reference/azr_dataset.md)
object.
