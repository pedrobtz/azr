# Report the Azure environment configuration

Reports the Azure environment variables used during credential
discovery, the value each one resolves to, and where that value came
from. This is the same information shown in the package startup banner.

`AZURE_CLIENT_SECRET` is never reported verbatim: when it is set, its
value is returned as `<<REDACTED>>`.

## Usage

``` r
az_config()
```

## Value

A `data.frame` with one row per environment variable and the columns:

- `variable`:

  Name of the environment variable.

- `value`:

  The resolved value, or `NA` when the variable is unset and has no
  built-in fallback.

- `source`:

  Where the value came from: `"env"` when read from the environment,
  `"default"` when it falls back to a built-in value, or `"unset"` when
  the variable is not set and has no fallback.

## See also

[`default_azure_tenant_id()`](https://pedrobtz.github.io/azr/reference/default_azure_tenant_id.md),
[`default_azure_client_id()`](https://pedrobtz.github.io/azr/reference/default_azure_client_id.md),
[`default_azure_config_dir()`](https://pedrobtz.github.io/azr/reference/default_azure_config_dir.md)

## Examples

``` r
az_config()
#>                     variable                                value
#> 1            AZURE_TENANT_ID                               common
#> 2            AZURE_CLIENT_ID 04b07795-8ddb-461a-bbee-02f9e1bf7b46
#> 3        AZURE_CLIENT_SECRET                                 <NA>
#> 4       AZURE_AUTHORITY_HOST            login.microsoftonline.com
#> 5           AZURE_CONFIG_DIR                             ~/.azure
#> 6 AZURE_FEDERATED_TOKEN_FILE                                 <NA>
#>    source
#> 1 default
#> 2 default
#> 3   unset
#> 4 default
#> 5 default
#> 6   unset

# which variables are actually set in the environment?
config <- az_config()
config[config$source == "env", ]
#> [1] variable value    source  
#> <0 rows> (or 0-length row.names)
```
