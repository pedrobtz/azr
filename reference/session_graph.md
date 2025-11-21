# Create Microsoft Graph API Session

Creates a new API session configured for Microsoft Graph API with
automatic Azure authentication. This is a convenience function that sets
up the correct host URL and credentials for accessing Microsoft Graph
services.

## Usage

``` r
session_graph(version = "v1.0", .chain = NULL)
```

## Arguments

- version:

  A character string specifying the Microsoft Graph API version to use.
  Defaults to `"v1.0"`. Common values are `"v1.0"` for the stable API
  and `"beta"` for preview features.

- .chain:

  An optional credential chain object to use for authentication. If
  `NULL`, uses the default credential chain. See
  [`get_request_authorizer()`](https://pedrobtz.github.io/azr/reference/get_request_authorizer.md)
  for details.

## Value

An
[api_session](https://pedrobtz.github.io/azr/reference/api_session.md)
object configured for Microsoft Graph API

## Details

The function automatically configures:

- Host URL: `https://graph.microsoft.com/{version}`

- Scope: Default Azure Graph scope

- Tenant: Default Azure tenant ID

- Credentials: Azure request authorizer with the configured scope and
  tenant

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a session for Microsoft Graph v1.0 API
graph <- session_graph()
graph$.client$.fetch("me")

# Create a session for Microsoft Graph beta API
graph_beta <- session_graph(version = "beta")

# Use the session to make API calls
# users <- graph$.client$.fetch("/users")
} # }
```
