# Get default MSAL token cache path

Returns the path to the MSAL token cache file shared by the Azure CLI
and Azure SDKs. Defaults to `msal_token_cache.json` inside the Azure
config directory (see
[`default_azure_config_dir()`](https://pedrobtz.github.io/azr/reference/default_azure_config_dir.md)).

## Usage

``` r
default_msal_token_cache()
```

## Value

A character string with the path to the MSAL token cache file.

## See also

[`default_azure_config_dir()`](https://pedrobtz.github.io/azr/reference/default_azure_config_dir.md),
[`write_msal_token()`](https://pedrobtz.github.io/azr/reference/write_msal_token.md)
