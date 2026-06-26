# Create Cached Token Credential Chain

Creates the default chain of credentials to attempt for cached token
retrieval. The credentials are tried in order until one returns a valid
cached token. The default chain includes:

1.  Authorization Code Credential - Cached tokens from browser-based
    authentication

2.  Device Code Credential - Cached tokens from device code flow

3.  Azure CLI Credential - Cached tokens from Azure CLI authentication

## Usage

``` r
cached_token_credential_chain(scope = NULL, tenant_id = NULL, client_id = NULL)
```

## Arguments

- scope:

  Optional character string specifying the authentication scope.

- tenant_id:

  Optional character string specifying the tenant ID for authentication.

- client_id:

  Optional character string specifying the client ID for authentication.

## Value

A `credential_chain` object containing the sequence of credential
providers to check for cached tokens.

## See also

[CachedTokenCredential](https://pedrobtz.github.io/azr/reference/CachedTokenCredential.md),
[`credential_chain()`](https://pedrobtz.github.io/azr/reference/credential_chain.md)
