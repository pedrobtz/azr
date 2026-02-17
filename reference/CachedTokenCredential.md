# Cached token credential authentication

A credential class that retrieves tokens from the cache only, without
triggering interactive authentication flows. This is useful for
non-interactive sessions where you want to use previously cached tokens
from DeviceCode or AuthCode credentials.

## Details

This credential attempts to retrieve cached tokens from a chain of
interactive credentials (AuthCode and DeviceCode by default). It will
not prompt for new authentication - it only returns tokens that are
already cached.

This is particularly useful for:

- Non-interactive R sessions (e.g., scheduled scripts, CI/CD)

- Scenarios where you've previously authenticated interactively and want
  to reuse those cached tokens

## Public fields

- `.scope`:

  Character string specifying the authentication scope.

- `.tenant_id`:

  Character string specifying the tenant ID.

- `.client_id`:

  Character string specifying the client ID.

- `.chain`:

  List of credential classes to attempt for cached tokens.

## Active bindings

- `provider`:

  Lazily initialized credential provider

## Methods

### Public methods

- [`CachedTokenCredential$new()`](#method-CachedTokenCredential-new)

- [`CachedTokenCredential$get_token()`](#method-CachedTokenCredential-get_token)

- [`CachedTokenCredential$req_auth()`](#method-CachedTokenCredential-req_auth)

- [`CachedTokenCredential$clone()`](#method-CachedTokenCredential-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new CachedTokenCredential object

#### Usage

    CachedTokenCredential$new(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      chain = cached_token_credential_chain()
    )

#### Arguments

- `scope`:

  Optional character string specifying the authentication scope.

- `tenant_id`:

  Optional character string specifying the tenant ID for authentication.

- `client_id`:

  Optional character string specifying the client ID for authentication.

- `chain`:

  A list of credential classes to attempt for cached tokens. Defaults to
  AuthCodeCredential and DeviceCodeCredential.

#### Returns

A new `CachedTokenCredential` object

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token from the cache

#### Usage

    CachedTokenCredential$get_token()

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add authentication to an httr2 request

#### Usage

    CachedTokenCredential$req_auth(req)

#### Arguments

- `req`:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

#### Returns

The request object with authentication configured

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CachedTokenCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create credential with default settings
cred <- CachedTokenCredential$new(
  scope = "https://graph.microsoft.com/.default",
  tenant_id = "my-tenant-id"
)

# Get a cached token (will fail if no cached token exists)
token <- cred$get_token()

# Use with httr2 request
req <- httr2::request("https://graph.microsoft.com/v1.0/me")
req <- cred$req_auth(req)
} # }
```
