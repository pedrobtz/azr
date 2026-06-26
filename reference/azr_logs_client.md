# Create an Azure Log Analytics Client

A convenience wrapper around
[api_log_analytics_client](https://pedrobtz.github.io/azr/reference/api_log_analytics_client.md)
that creates a configured client for the Azure Log Analytics query REST
API, bound to a specific subscription and resource group.

## Usage

``` r
azr_logs_client(
  subscription_id,
  resource_id,
  endpoint = default_log_analytics_endpoint(),
  api_version = "v1",
  scope = default_azure_scope("azure_log_analytics"),
  provider = NULL,
  chain = default_credential_chain(),
  tenant_id = default_azure_tenant_id(),
  ...
)
```

## Arguments

- subscription_id:

  A character string specifying the Azure subscription ID (GUID) to bind
  the client to.

- resource_id:

  A character string specifying the Azure resource group name to bind
  the client to.

- endpoint:

  A character string specifying the Log Analytics query endpoint host.
  Defaults to
  [`default_log_analytics_endpoint()`](https://pedrobtz.github.io/azr/reference/default_log_analytics_endpoint.md).

- api_version:

  A character string specifying the API version segment. Defaults to
  `"v1"`.

- scope:

  A character string specifying the OAuth2 scope. Defaults to
  `default_azure_scope("azure_log_analytics")`.

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
  [`default_azure_tenant_id()`](https://pedrobtz.github.io/azr/reference/default_azure_tenant_id.md).

- ...:

  Additional arguments passed to the
  [api_log_analytics_client](https://pedrobtz.github.io/azr/reference/api_log_analytics_client.md)
  constructor.

## Value

An
[api_log_analytics_client](https://pedrobtz.github.io/azr/reference/api_log_analytics_client.md)
object.

## Examples

``` r
if (FALSE) { # \dontrun{
la <- azr_logs_client(
  subscription_id = "00000000-0000-0000-0000-000000000000",
  resource_id = "my-resource-group"
)

la$query(
  query = "AzureDiagnostics | take 10",
  timespan = "PT12H",
  scope = "hierarchy"
)
} # }
```
