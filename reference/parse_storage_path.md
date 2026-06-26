# Parse an Azure Storage path

Splits an Azure Storage URL or Hadoop filesystem path into its
constituent parts. Supports all common Azure Storage path formats:

- `abfss://` / `abfs://`:

  Azure Data Lake Storage Gen2 (DFS endpoint), used by Spark / Hadoop.

- `wasbs://` / `wasb://`:

  Legacy Azure Blob filesystem scheme, used by older Spark / Hadoop
  integrations.

- `https://` / `http://`:

  Standard Azure Blob or DFS REST endpoint, optionally with a SAS token
  query string.

- `az://` / `azure://`:

  Non-standard aliases used by some Python tools (e.g. `adlfs`); parsed
  using the same `container@account.host/path` shape as `abfs://`.

The `format` field is inferred from the path on a best-effort basis:
`"delta"` when the path contains `_delta_log`; a file extension name
(`"parquet"`, `"csv"`, `"json"`, `"avro"`, `"orc"`, `"text"`) when the
last path segment has a recognised extension; `"folder"` when there is
no extension; and `NA` for unrecognised extensions.

## Usage

``` r
parse_storage_path(path)
```

## Arguments

- path:

  A character string containing the Azure Storage path to parse.

## Value

An `azure_storage_path` object (a named list) with the fields:

- `scheme`:

  URL scheme, e.g. `"abfss"`, `"wasbs"`, `"https"`.

- `storage_account`:

  Storage account name.

- `endpoint`:

  Storage endpoint type: `"dfs"` or `"blob"`.

- `endpoint_suffix`:

  Host suffix after the endpoint label, e.g. `"core.windows.net"` (Azure
  public), `"core.usgovcloudapi.net"` (US Government),
  `"core.chinacloudapi.cn"` (China), or `"storage.azure.net"` (DNS-zone
  endpoints). Use this to distinguish sovereign clouds from the public
  cloud.

- `container`:

  Container name. Called "filesystem" in ADLS Gen2 / ABFS contexts; both
  refer to the same underlying object.

- `path`:

  Path within the container, without a leading `/`. Empty string if the
  URL points to the container root.

- `format`:

  Inferred dataset or file format (see above).

- `query`:

  Named list of query parameters (e.g. a parsed SAS token), or `NULL` if
  none.

- `original`:

  The original input string.

## Examples

``` r
parse_storage_path(
  "abfss://mycontainer@myaccount.dfs.core.windows.net/data/sales/2024"
)
#> $scheme
#> [1] "abfss"
#> 
#> $storage_account
#> [1] "myaccount"
#> 
#> $endpoint
#> [1] "dfs"
#> 
#> $endpoint_suffix
#> [1] "core.windows.net"
#> 
#> $container
#> [1] "mycontainer"
#> 
#> $path
#> [1] "data/sales/2024"
#> 
#> $format
#> [1] "folder"
#> 
#> $query
#> NULL
#> 
#> $original
#> [1] "abfss://mycontainer@myaccount.dfs.core.windows.net/data/sales/2024"
#> 
#> attr(,"class")
#> [1] "azure_storage_path"

parse_storage_path(
  "https://myaccount.blob.core.windows.net/mycontainer/data/events.parquet"
)
#> $scheme
#> [1] "https"
#> 
#> $storage_account
#> [1] "myaccount"
#> 
#> $endpoint
#> [1] "blob"
#> 
#> $endpoint_suffix
#> [1] "core.windows.net"
#> 
#> $container
#> [1] "mycontainer"
#> 
#> $path
#> [1] "data/events.parquet"
#> 
#> $format
#> [1] "parquet"
#> 
#> $query
#> NULL
#> 
#> $original
#> [1] "https://myaccount.blob.core.windows.net/mycontainer/data/events.parquet"
#> 
#> attr(,"class")
#> [1] "azure_storage_path"

parse_storage_path(
  "wasbs://mycontainer@myaccount.blob.core.windows.net/data/delta_table"
)
#> $scheme
#> [1] "wasbs"
#> 
#> $storage_account
#> [1] "myaccount"
#> 
#> $endpoint
#> [1] "blob"
#> 
#> $endpoint_suffix
#> [1] "core.windows.net"
#> 
#> $container
#> [1] "mycontainer"
#> 
#> $path
#> [1] "data/delta_table"
#> 
#> $format
#> [1] "folder"
#> 
#> $query
#> NULL
#> 
#> $original
#> [1] "wasbs://mycontainer@myaccount.blob.core.windows.net/data/delta_table"
#> 
#> attr(,"class")
#> [1] "azure_storage_path"
```
