# Create a Microsoft Graph API Client

Creates a configured client for the Microsoft Graph API with
authentication and versioned endpoints (v1.0 and beta). This function
returns an
[api_graph_service](https://pedrobtz.github.io/azr/reference/api_graph_service.md)
object that provides access to Microsoft Graph resources through
versioned endpoints.

## Usage

``` r
azr_graph_client(chain = NULL, ...)
```

## Arguments

- chain:

  A
  [credential_chain](https://pedrobtz.github.io/azr/reference/credential_chain.md)
  instance for authentication. If NULL, a default credential chain will
  be created using
  [`get_credential_provider()`](https://pedrobtz.github.io/azr/reference/get_credential_provider.md).

- ...:

  Additional arguments passed to the internal
  [api_graph_client](https://pedrobtz.github.io/azr/reference/api_graph_client.md)
  constructor.

## Value

An
[api_graph_service](https://pedrobtz.github.io/azr/reference/api_graph_service.md)
object configured for Microsoft Graph API with v1.0 and beta endpoints.
The object is locked using
[`lockEnvironment()`](https://rdrr.io/r/base/bindenv.html) to prevent
modification after creation. Access endpoints via `$v1.0` or `$beta`.

## Details

The returned service object is built using three internal R6 classes:

### api_graph_client

An R6 class extending
[api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
with Microsoft Graph-specific defaults. Preconfigured with the Graph API
host URL (`https://graph.microsoft.com`).

### api_graph_resource

An R6 class extending
[api_resource](https://pedrobtz.github.io/azr/reference/api_resource.md)
that provides specialized methods for the Microsoft Graph API. Currently
implements:

- `me(select = NULL)`: Fetch the current user's profile. The `select`
  parameter accepts a character vector of properties to return (e.g.,
  `c("displayName", "mail")`).

### api_graph_service

An R6 class extending
[api_service](https://pedrobtz.github.io/azr/reference/api_service.md)
that combines the client and resources into a cohesive service with
versioned endpoints (v1.0 and beta). Handles credential provider
initialization using
[`get_credential_provider()`](https://pedrobtz.github.io/azr/reference/get_credential_provider.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a Graph API client with default credentials
graph <- azr_graph_client()

# Fetch current user profile from v1.0 endpoint
me <- graph$v1.0$me()

# Fetch specific properties using OData $select
me <- graph$v1.0$me(select = c("displayName", "mail", "userPrincipalName"))

# Use beta endpoint for preview features
me_beta <- graph$beta$me(select = c("displayName", "mail"))

# Create with a custom credential chain
custom_chain <- credential_chain(
  AzureCLICredential$new(scope = "https://graph.microsoft.com/.default")
)
graph <- azr_graph_client(chain = custom_chain)
} # }
```
