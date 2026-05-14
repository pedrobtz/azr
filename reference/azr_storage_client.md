# Create an Azure Storage Client

A convenience wrapper around
[api_storage_client](https://pedrobtz.github.io/azr/reference/api_storage_client.md)
that creates a configured client for Azure Data Lake Storage Gen2 (ADLS
Gen2) REST API operations.

## Usage

``` r
azr_storage_client(
  storageaccount,
  filesystem,
  endpoint_suffix = default_storage_endpoint(),
  scope = default_azure_scope("azure_storage"),
  provider = NULL,
  chain = default_credential_chain(),
  tenant_id = default_azure_tenant_id(),
  ...
)
```

## Arguments

- storageaccount:

  A character string specifying the Azure Storage account name.

- filesystem:

  A character string specifying the filesystem (container) name.

- endpoint_suffix:

  A character string specifying the Azure Storage DFS endpoint suffix.
  Defaults to
  [`default_storage_endpoint()`](https://pedrobtz.github.io/azr/reference/default_storage_endpoint.md).

- scope:

  A character string specifying the OAuth2 scope. Defaults to
  `default_azure_scope("azure_storage")`.

- provider:

  An optional credential provider object that inherits from `Credential`
  or `DefaultCredential`. If provided, `chain` is ignored.

- chain:

  A
  [credential_chain](https://pedrobtz.github.io/azr/reference/credential_chain.md)
  instance for authentication. Defaults to
  [`default_credential_chain()`](https://pedrobtz.github.io/azr/reference/default_credential_chain.md).

- tenant_id:

  A character string specifying the Azure tenant ID. Defaults to
  [`default_azure_tenant_id()`](https://pedrobtz.github.io/azr/reference/default_azure_tenant_id.md),
  which reads `AZURE_TENANT_ID` from the environment.

- ...:

  Additional arguments passed to the
  [api_storage_client](https://pedrobtz.github.io/azr/reference/api_storage_client.md)
  constructor.

## Value

An
[api_storage_client](https://pedrobtz.github.io/azr/reference/api_storage_client.md)
object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a storage client with default credentials
storage <- azr_storage_client(
  storageaccount = "mystorageaccount",
  filesystem = "mycontainer"
)

# Create a storage client with a specific tenant
storage <- azr_storage_client(
  storageaccount = "mystorageaccount",
  filesystem = "mycontainer",
  tenant_id = "00000000-0000-0000-0000-000000000000"
)
} # }
```
