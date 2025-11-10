# Create Custom Credential Chain

Creates a custom chain of credential providers to attempt during
authentication. Credentials are tried in the order they are provided
until one successfully authenticates. This allows you to customize the
authentication flow beyond the default credential chain.

## Usage

``` r
credential_chain(...)
```

## Arguments

- ...:

  Named credential objects or credential classes. Each element should be
  a credential class (e.g., `ClientSecretCredential`) or an instantiated
  credential object that inherits from the `Credential` base class. The
  names are used for identification purposes.

## Value

A `credential_chain` object containing the specified sequence of
credential providers.

## See also

[`default_credential_chain()`](https://pedrobtz.github.io/azr/reference/default_credential_chain.md),
[`get_token_provider()`](https://pedrobtz.github.io/azr/reference/get_token_provider.md)

## Examples

``` r
# Create a custom chain with only non-interactive credentials
custom_chain <- credential_chain(
  client_secret = ClientSecretCredential,
  azure_cli = AzureCLICredential
)

# Use the custom chain to get a token
if (FALSE) { # \dontrun{
token <- get_token(
  scope = "https://graph.microsoft.com/.default",
  .chain = custom_chain
)
} # }
```
