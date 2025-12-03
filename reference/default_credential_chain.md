# Create Default Credential Chain

Creates the default chain of credentials to attempt during
authentication. The credentials are tried in order until one
successfully authenticates. The default chain includes:

1.  Client Secret Credential - Uses client ID and secret

2.  Authorization Code Credential - Interactive browser-based
    authentication

3.  Azure CLI Credential - Uses credentials from Azure CLI

4.  Device Code Credential - Interactive device code flow

## Usage

``` r
default_credential_chain()
```

## Value

A `credential_chain` object containing the default sequence of
credential providers.

## See also

[`credential_chain()`](https://pedrobtz.github.io/azr/reference/credential_chain.md),
[`get_token_provider()`](https://pedrobtz.github.io/azr/reference/get_token_provider.md)
