# Get default Azure configuration directory

Retrieves the Azure configuration directory from the `AZURE_CONFIG_DIR`
environment variable, or falls back to the platform-specific default.

## Usage

``` r
default_azure_config_dir()
```

## Value

A character string with the Azure configuration directory path

## Examples

``` r
default_azure_config_dir()
#> [1] "~/.azure"
```
