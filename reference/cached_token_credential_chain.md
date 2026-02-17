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
cached_token_credential_chain()
```

## Value

A `credential_chain` object containing the sequence of credential
providers to check for cached tokens.

## See also

[CachedTokenCredential](https://pedrobtz.github.io/azr/reference/CachedTokenCredential.md),
[`credential_chain()`](https://pedrobtz.github.io/azr/reference/credential_chain.md)
