# Managed identity credential authentication

Authenticates using an Azure managed identity. Supports both
system-assigned and user-assigned managed identities. This credential
works when code is running inside an Azure environment that has a
managed identity configured (e.g., VMs, App Service, Container
Instances, AKS pods).

## Details

Authentication is performed by querying the Azure Instance Metadata
Service (IMDS) endpoint at
`http://169.254.169.254/metadata/identity/oauth2/token`. No credentials
need to be stored — the identity is granted by the Azure platform.

To use a **system-assigned** managed identity, leave `client_id` as
`NULL`. To use a **user-assigned** managed identity, supply its
`client_id`.

This credential fails immediately (2-second timeout) when not running
inside Azure, so it is safe to include early in a credential chain.

## Super class

`azr::Credential` -\> `ManagedIdentityCredential`

## Public fields

- `.msi_client_id`:

  Client ID for user-assigned managed identity, or `NULL` for
  system-assigned.

## Methods

### Public methods

- [`ManagedIdentityCredential$new()`](#method-ManagedIdentityCredential-new)

- [`ManagedIdentityCredential$get_token()`](#method-ManagedIdentityCredential-get_token)

- [`ManagedIdentityCredential$req_auth()`](#method-ManagedIdentityCredential-req_auth)

- [`ManagedIdentityCredential$clone()`](#method-ManagedIdentityCredential-clone)

Inherited methods

- [`azr::Credential$is_interactive()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-is_interactive)
- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)
- [`azr::Credential$validate()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-validate)

------------------------------------------------------------------------

### Method `new()`

Create a new managed identity credential

#### Usage

    ManagedIdentityCredential$new(scope = NULL, client_id = NULL)

#### Arguments

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to the Azure
  Resource Manager scope.

- `client_id`:

  A character string specifying the client ID of a user-assigned managed
  identity. Leave `NULL` (the default) to use the system-assigned
  managed identity.

#### Returns

A new `ManagedIdentityCredential` object

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token from the IMDS endpoint

#### Usage

    ManagedIdentityCredential$get_token()

#### Details

Returns a valid in-object cached token immediately if one exists.
Otherwise queries the Azure Instance Metadata Service (IMDS) for a new
token.

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add managed identity authentication to an httr2 request

#### Usage

    ManagedIdentityCredential$req_auth(req)

#### Arguments

- `req`:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

#### Returns

The request object with a Bearer token authorization header

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    ManagedIdentityCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# System-assigned managed identity (no client_id needed)
cred <- ManagedIdentityCredential$new(
  scope = "https://management.azure.com/.default"
)

# User-assigned managed identity
cred <- ManagedIdentityCredential$new(
  scope = "https://management.azure.com/.default",
  client_id = "your-user-assigned-client-id"
)

token <- cred$get_token()
} # }
```
