# Refresh token credential authentication

Authenticates using an existing refresh token. This credential is useful
when you have obtained a refresh token through another authentication
flow and want to use it to get new access tokens without interactive
authentication.

## Details

The refresh token credential uses the OAuth 2.0 refresh token flow to
obtain new access tokens. It requires a valid refresh token that was
previously obtained through an interactive flow (e.g., authorization
code or device code).

This is particularly useful for:

- Non-interactive sessions where you have a pre-obtained refresh token

- Long-running applications that need to refresh tokens automatically

- Scenarios where you want to avoid repeated interactive authentication

## Super class

`azr::Credential` -\> `RefreshTokenCredential`

## Public fields

- `.refresh_token`:

  Character string containing the refresh token.

## Methods

### Public methods

- [`RefreshTokenCredential$new()`](#method-RefreshTokenCredential-new)

- [`RefreshTokenCredential$validate()`](#method-RefreshTokenCredential-validate)

- [`RefreshTokenCredential$get_token()`](#method-RefreshTokenCredential-get_token)

- [`RefreshTokenCredential$req_auth()`](#method-RefreshTokenCredential-req_auth)

- [`RefreshTokenCredential$clone()`](#method-RefreshTokenCredential-clone)

Inherited methods

- [`azr::Credential$is_interactive()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-is_interactive)
- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)

------------------------------------------------------------------------

### Method `new()`

Create a new refresh token credential

#### Usage

    RefreshTokenCredential$new(
      refresh_token = default_refresh_token(),
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL
    )

#### Arguments

- `refresh_token`:

  A character string containing the refresh token. Defaults to
  [`default_refresh_token()`](https://pedrobtz.github.io/azr/reference/default_refresh_token.md)
  which reads from the `AZURE_REFRESH_TOKEN` environment variable.

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to `NULL`.

- `tenant_id`:

  A character string specifying the Azure Active Directory tenant ID.
  Defaults to `NULL`.

- `client_id`:

  A character string specifying the application (client) ID. Defaults to
  `NULL`.

#### Returns

A new `RefreshTokenCredential` object

------------------------------------------------------------------------

### Method `validate()`

Validate the credential configuration

#### Usage

    RefreshTokenCredential$validate()

#### Details

Checks that the refresh token is provided and not NA or NULL. Calls the
parent class validation method.

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token using the refresh token flow

#### Usage

    RefreshTokenCredential$get_token()

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add OAuth refresh token authentication to an httr2 request

#### Usage

    RefreshTokenCredential$req_auth(req)

#### Arguments

- `req`:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

#### Returns

The request object with OAuth refresh token authentication configured

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    RefreshTokenCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create credential with a refresh token
cred <- RefreshTokenCredential$new(
  refresh_token = "your-refresh-token",
  scope = "https://management.azure.com/.default",
  tenant_id = "your-tenant-id",
  client_id = "your-client-id"
)

# Get an access token
token <- cred$get_token()

# Use with httr2 request
req <- httr2::request("https://management.azure.com/subscriptions")
resp <- httr2::req_perform(cred$req_auth(req))
} # }
```
