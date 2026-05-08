# Workload Identity credential authentication

Authenticates using Azure Workload Identity by reading a federated token
from a file and exchanging it for an Azure AD access token. This is
commonly used in Kubernetes environments (AKS) where a service account
token is mounted into the pod.

## Details

The credential implements the OAuth 2.0 client credentials flow with a
JWT bearer assertion (`client_assertion`). It reads the federated
identity token from a file on each call to
[`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)
so that token rotation by the runtime (e.g., Kubernetes) is
automatically picked up.

The following environment variables are used when parameters are not
provided:

- `AZURE_CLIENT_ID`: Client (application) ID of the Azure AD application

- `AZURE_TENANT_ID`: Azure AD tenant ID

- `AZURE_FEDERATED_TOKEN_FILE`: Path to the file containing the
  federated token

## Super class

`azr::Credential` -\> `WorkloadIdentityCredential`

## Public fields

- `.token_file_path`:

  Path to the file containing the federated identity token

## Methods

### Public methods

- [`WorkloadIdentityCredential$new()`](#method-WorkloadIdentityCredential-new)

- [`WorkloadIdentityCredential$validate()`](#method-WorkloadIdentityCredential-validate)

- [`WorkloadIdentityCredential$get_token()`](#method-WorkloadIdentityCredential-get_token)

- [`WorkloadIdentityCredential$req_auth()`](#method-WorkloadIdentityCredential-req_auth)

- [`WorkloadIdentityCredential$clone()`](#method-WorkloadIdentityCredential-clone)

Inherited methods

- [`azr::Credential$is_interactive()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-is_interactive)
- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)

------------------------------------------------------------------------

### Method `new()`

Create a new Workload Identity credential

#### Usage

    WorkloadIdentityCredential$new(
      scope = NULL,
      tenant_id = Sys.getenv(environment_variables$azure_tenant_id, unset = NA_character_),
      client_id = Sys.getenv(environment_variables$azure_client_id, unset = NA_character_),
      token_file_path = default_federated_token_file()
    )

#### Arguments

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to the Azure
  Resource Manager scope.

- `tenant_id`:

  A character string specifying the Azure AD tenant ID. Defaults to the
  `AZURE_TENANT_ID` environment variable.

- `client_id`:

  A character string specifying the client (application) ID. Defaults to
  the `AZURE_CLIENT_ID` environment variable.

- `token_file_path`:

  A character string specifying the path to the file containing the
  federated identity token. Defaults to the `AZURE_FEDERATED_TOKEN_FILE`
  environment variable.

#### Returns

A new `WorkloadIdentityCredential` object

------------------------------------------------------------------------

### Method `validate()`

Validate the credential configuration

#### Usage

    WorkloadIdentityCredential$validate()

#### Details

Checks that `token_file_path` is provided and not NA. Calls the parent
class validation method.

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token by exchanging the federated token

#### Usage

    WorkloadIdentityCredential$get_token()

#### Details

Returns a valid in-object cached token immediately if one exists.
Otherwise reads the federated token from the file and exchanges it for a
new access token so that token rotation performed by the runtime is
automatically reflected.

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add authentication to an httr2 request

#### Usage

    WorkloadIdentityCredential$req_auth(req)

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

    WorkloadIdentityCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create credential using environment variables
# (requires AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_FEDERATED_TOKEN_FILE)
cred <- WorkloadIdentityCredential$new(
  scope = "https://management.azure.com/.default"
)

# Or supply parameters directly
cred <- WorkloadIdentityCredential$new(
  tenant_id = "your-tenant-id",
  client_id = "your-client-id",
  token_file_path = "/var/run/secrets/azure/tokens/azure-identity-token",
  scope = "https://management.azure.com/.default"
)

# Get an access token
token <- cred$get_token()

# Use with httr2 request
req <- httr2::request("https://management.azure.com/subscriptions")
resp <- httr2::req_perform(cred$req_auth(req))
} # }
```
