# Create a Microsoft Graph API Client

Creates a configured client for the Microsoft Graph API with
authentication and versioned endpoints (v1.0 and beta). This function
returns an
[api_service](https://pedrobtz.github.io/azr/reference/api_service.md)
object that provides access to Microsoft Graph resources through
versioned endpoints.

## Usage

``` r
azr_graph_client(scopes = ".default", ..., chain = NULL)
```

## Arguments

- scopes:

  A character string specifying the OAuth2 scope suffix to be appended
  to the Graph API URL. Defaults to `".default"`, which requests all
  permissions the app has been granted. The full scope will be
  `https://graph.microsoft.com/{scopes}`.

- ...:

  Additional arguments passed to the
  [api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
  constructor.

- chain:

  A
  [credential_chain](https://pedrobtz.github.io/azr/reference/credential_chain.md)
  instance for authentication. If NULL, a default credential chain will
  be created using
  [DefaultCredential](https://pedrobtz.github.io/azr/reference/DefaultCredential.md).

## Value

An
[api_service](https://pedrobtz.github.io/azr/reference/api_service.md)
object configured for Microsoft Graph API with v1.0 and beta endpoints.
The object is locked using
[`lockEnvironment()`](https://rdrr.io/r/base/bindenv.html) to prevent
modification after creation. Access endpoints via `$v1.0` or `$beta`.

## Details

The function creates a Microsoft Graph service using these components:

- **[api_client](https://pedrobtz.github.io/azr/reference/api_client.md)**:
  A general-purpose API client configured with the Graph API host URL
  (`https://graph.microsoft.com`) and authentication provider.

- **[api_graph_resource](https://pedrobtz.github.io/azr/reference/api_graph_resource.md)**:
  A specialized resource class that extends
  [api_resource](https://pedrobtz.github.io/azr/reference/api_resource.md)
  with Microsoft Graph-specific methods. Currently implements:

  - `me(select = NULL)`: Fetch the current user's profile. The `select`
    parameter accepts a character vector of properties to return (e.g.,
    `c("displayName", "mail")`).

- **[api_service](https://pedrobtz.github.io/azr/reference/api_service.md)**:
  A service container that combines the client and resources with
  versioned endpoints (v1.0 and beta). The service is locked using
  [`lockEnvironment()`](https://rdrr.io/r/base/bindenv.html) to prevent
  modification after creation.

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

# Use specific scopes instead of .default
graph <- azr_graph_client(scopes = "User.Read Mail.Read")
} # }
```
