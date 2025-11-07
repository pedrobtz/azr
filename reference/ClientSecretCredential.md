# Client secret credential authentication

Authenticates a service principal using a client ID and client secret.
This credential is commonly used for application authentication in
Azure.

## Details

The credential uses the OAuth 2.0 client credentials flow to obtain
access tokens. It requires a registered Azure AD application with a
client secret. The client secret should be stored securely and not
hard-coded in scripts.

## Super class

`azr::Credential` -\> `ClientSecretCredential`

## Methods

### Public methods

- [`ClientSecretCredential$validate()`](#method-ClientSecretCredential-validate)

- [`ClientSecretCredential$get_token()`](#method-ClientSecretCredential-get_token)

- [`ClientSecretCredential$req_auth()`](#method-ClientSecretCredential-req_auth)

- [`ClientSecretCredential$clone()`](#method-ClientSecretCredential-clone)

Inherited methods

- [`azr::Credential$initialize()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-initialize)
- [`azr::Credential$is_interactive()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-is_interactive)
- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)

------------------------------------------------------------------------

### Method `validate()`

Validate the credential configuration

#### Usage

    ClientSecretCredential$validate()

#### Details

Checks that the client secret is provided and not NA or NULL. Calls the
parent class validation method.

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token using client credentials flow

#### Usage

    ClientSecretCredential$get_token()

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add OAuth client credentials authentication to an httr2 request

#### Usage

    ClientSecretCredential$req_auth(req)

#### Arguments

- `req`:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

#### Returns

The request object with OAuth client credentials authentication
configured

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    ClientSecretCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Create credential with client secret
cred <- ClientSecretCredential$new(
  tenant_id = "your-tenant-id",
  client_id = "your-client-id",
  client_secret = "your-client-secret",
  scope = "https://management.azure.com/.default"
)

# To get a token or authenticate a request it requires
# valid 'client_id' and 'client_secret' credentials,
# otherwise it will return an error.
if (FALSE) { # \dontrun{
# Get an access token
token <- cred$get_token()

# Use with httr2 request
req <- httr2::request("https://management.azure.com/subscriptions")
resp <- httr2::req_perform(cred$req_auth(req))
} # }
```
