# List all azr options and their current values

Prints every azr option and invisibly returns a
[data.frame](https://rdrr.io/r/base/data.frame.html) of the same
information. The resolution order is: a value set for the session -\>
`options(azr.*)` -\> the option's environment variable -\> a built-in
default.

|  |  |  |  |  |
|----|----|----|----|----|
| Name | R option | Env variable | Default | Description |
| `"chain_verbose"` | `azr.chain_verbose` | `AZR_CHAIN_VERBOSE` | `FALSE` | Verbose credential-chain discovery |
| `"api_verbose"` | `azr.api_verbose` | `AZR_API_VERBOSE` | `FALSE` | Verbose api_client request/response |
| `"cli_auto_login"` | `azr.cli_auto_login` | `AZR_CLI_AUTO_LOGIN` | `FALSE` | Auto Azure CLI login |
| `"dataset_tier"` | `azr.dataset_tier` | `AZR_DATASET_TIER` | `"prod"` | Default tier for [`azr_dataset_uri()`](https://pedrobtz.github.io/azr/reference/azr_dataset_uri.md) |

## Usage

``` r
azr_options(mask = TRUE)
```

## Arguments

- mask:

  Logical. When `TRUE` (default), sensitive option values are shown as
  `"<hidden>"` when set.

## Value

Invisibly, a [data.frame](https://rdrr.io/r/base/data.frame.html) with
columns `option`, `value`, `source`, `env_var`, `env_value`, and
`default`.

## Examples

``` r
azr_options()
#> 
#> ── azr options ────────────────────────────────────────────────────────
#> api_verbose = "FALSE" (default)
#>   `AZR_API_VERBOSE`: (not set)
#> chain_verbose = "FALSE" (default)
#>   `AZR_CHAIN_VERBOSE`: (not set)
#> cli_auto_login = "FALSE" (default)
#>   `AZR_CLI_AUTO_LOGIN`: (not set)
#> dataset_tier = "prod" (default)
#>   `AZR_DATASET_TIER`: (not set)

# Set for the session
options(azr.chain_verbose = TRUE)

# Or via environment variable (before starting R)
# AZR_CHAIN_VERBOSE=true
```
