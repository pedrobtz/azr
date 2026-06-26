# Azure Storage API Class

An R6 class that extends
[api_client](https://pedrobtz.github.io/azr/reference/api_client.md) to
provide specialized methods for Azure Data Lake Storage Gen2 (ADLS Gen2)
REST API operations.

## Details

The base URL is constructed as:
`https://{storageaccount}.{endpoint_suffix}`

## Super class

[`azr::api_client`](https://pedrobtz.github.io/azr/reference/api_client.md)
-\> `api_storage_client`

## Public fields

- `.filesystem`:

  The filesystem (container) name

## Methods

### Public methods

- [`api_storage_client$new()`](#method-api_storage_client-new)

- [`api_storage_client$download_file()`](#method-api_storage_client-download_file)

- [`api_storage_client$get_access_control()`](#method-api_storage_client-get_access_control)

- [`api_storage_client$list_files()`](#method-api_storage_client-list_files)

- [`api_storage_client$clone()`](#method-api_storage_client-clone)

Inherited methods

- [`azr::api_client$.build_request()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.build_request)
- [`azr::api_client$.fetch()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.fetch)
- [`azr::api_client$.get_token()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.get_token)
- [`azr::api_client$.resp_body_content()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.resp_body_content)
- [`azr::api_client$.resp_content()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.resp_content)
- [`azr::api_client$.send_request()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.send_request)

------------------------------------------------------------------------

### Method `new()`

Create a new Azure Storage API client instance

#### Usage

    api_storage_client$new(
      storageaccount,
      filesystem,
      scope = default_azure_scope("azure_storage"),
      endpoint_suffix = default_storage_endpoint(),
      provider = NULL,
      chain = NULL,
      tenant_id = NULL,
      client_id = default_azure_cli_client_id(),
      ...
    )

#### Arguments

- `storageaccount`:

  A character string specifying the Azure Storage account name.

- `filesystem`:

  A character string specifying the filesystem (container) name.

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to
  `default_azure_scope("azure_storage")`.

- `endpoint_suffix`:

  A character string specifying the Azure Storage DFS endpoint suffix.
  Defaults to
  [`default_storage_endpoint()`](https://pedrobtz.github.io/azr/reference/default_storage_endpoint.md).

- `provider`:

  An optional credential provider object that inherits from `Credential`
  or `DefaultCredential`. If provided, `chain` is ignored.

- `chain`:

  A
  [credential_chain](https://pedrobtz.github.io/azr/reference/credential_chain.md)
  instance for authentication. If NULL, a default credential chain will
  be created using
  [DefaultCredential](https://pedrobtz.github.io/azr/reference/DefaultCredential.md).

- `tenant_id`:

  A character string specifying the Azure tenant ID. Passed to
  [DefaultCredential](https://pedrobtz.github.io/azr/reference/DefaultCredential.md)
  when `chain` is `NULL`.

- `client_id`:

  A character string specifying the Azure client ID. Passed to
  [DefaultCredential](https://pedrobtz.github.io/azr/reference/DefaultCredential.md)
  when `chain` is `NULL`. Defaults to
  [`default_azure_cli_client_id()`](https://pedrobtz.github.io/azr/reference/default_azure_cli_client_id.md).

- `...`:

  Additional arguments passed to the parent
  [api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
  constructor.

#### Returns

A new `api_storage_client` object

------------------------------------------------------------------------

### Method `download_file()`

Download a file from the filesystem

#### Usage

    api_storage_client$download_file(path, dest = NULL)

#### Arguments

- `path`:

  A character string specifying the file path within the filesystem.

- `dest`:

  A character string specifying the local destination path. Defaults to
  a temporary file via
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html).

#### Returns

The local path the file was written to (invisibly).

------------------------------------------------------------------------

### Method `get_access_control()`

Get the access control list (ACL) for a file or directory

#### Usage

    api_storage_client$get_access_control(dataset, upn = FALSE)

#### Arguments

- `dataset`:

  A character string specifying the file or directory path within the
  filesystem.

- `upn`:

  A logical value. If `TRUE`, user principal names (UPN) are returned in
  the `x-ms-owner`, `x-ms-group`, and `x-ms-acl` response headers
  instead of object IDs. Defaults to `FALSE`.

#### Returns

A data.frame with columns `group_id` and `permission`, one row per named
group entry in the `x-ms-acl` response header.

------------------------------------------------------------------------

### Method `list_files()`

List files and directories in a path

#### Usage

    api_storage_client$list_files(path = "", recursive = FALSE, ...)

#### Arguments

- `path`:

  A character string specifying the directory path to list. Use empty
  string or NULL for the root directory. Defaults to `""`.

- `recursive`:

  A logical value indicating whether to list files recursively. Defaults
  to `FALSE`.

- `...`:

  Additional query parameters to pass to the API.

#### Returns

A data.frame (or data.table if available) with one row per file or
directory. Columns include `name`, `contentLength`, `lastModified`, etc.
All pages are fetched transparently; the result is the complete listing.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    api_storage_client$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a storage client
storage <- api_storage_client$new(
  storageaccount = "mystorageaccount",
  filesystem = "mycontainer"
)

# List files in the root directory
files <- storage$list_files()

# List files in a specific path
files <- storage$list_files(path = "data/folder1")

# List files recursively
files <- storage$list_files(path = "data", recursive = TRUE)
} # }
```
