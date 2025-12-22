# Default credential authentication

An R6 class that provides lazy initialization of credential providers.
The credential provider is created on first access using the default
credential chain.

## Details

This class wraps the credential discovery process in an R6 object with a
lazily evaluated `provider` field. The provider is only created when
first accessed, using the same logic as
[`get_token_provider()`](https://pedrobtz.github.io/azr/reference/get_token_provider.md).

## Active bindings

- `provider`:

  Lazily initialized credential provider

## Methods

### Public methods

- [`DefaultCredential$new()`](#method-DefaultCredential-new)

- [`DefaultCredential$get_token()`](#method-DefaultCredential-get_token)

- [`DefaultCredential$req_auth()`](#method-DefaultCredential-req_auth)

- [`DefaultCredential$clone()`](#method-DefaultCredential-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new DefaultCredential object

#### Usage

    DefaultCredential$new(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      client_secret = NULL,
      use_cache = "disk",
      offline = TRUE,
      chain = default_credential_chain()
    )

#### Arguments

- `scope`:

  Optional character string specifying the authentication scope.

- `tenant_id`:

  Optional character string specifying the tenant ID for authentication.

- `client_id`:

  Optional character string specifying the client ID for authentication.

- `client_secret`:

  Optional character string specifying the client secret for
  authentication.

- `use_cache`:

  Character string indicating the caching strategy. Defaults to
  `"disk"`. Options include `"disk"` for disk-based caching or
  `"memory"` for in-memory caching.

- `offline`:

  Logical. If `TRUE`, adds 'offline_access' to the scope to request a
  'refresh_token'. Defaults to `TRUE`.

- `chain`:

  A list of credential objects, where each element must inherit from the
  `Credential` base class. Credentials are attempted in the order
  provided until `get_token` succeeds.

#### Returns

A new `DefaultCredential` object

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token using the credential chain

#### Usage

    DefaultCredential$get_token()

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add authentication to an httr2 request

#### Usage

    DefaultCredential$req_auth(req)

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

    DefaultCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Create a DefaultCredential object
cred <- DefaultCredential$new(
  scope = "https://graph.microsoft.com/.default",
  tenant_id = "my-tenant-id"
)

if (FALSE) { # \dontrun{
# Get a token (triggers lazy initialization)
token <- cred$get_token()

# Authenticate a request
req <- httr2::request("https://management.azure.com/subscriptions")
resp <- httr2::req_perform(cred$req_auth(req))

# Or access the provider directly
provider <- cred$provider
} # }
```
