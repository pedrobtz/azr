# Package-level defaults environment

Mutable environment for overriding package defaults at runtime via
[`set_azr_defaults()`](https://pedrobtz.github.io/azr/reference/set_azr_defaults.md).
`NULL` means "not set" and the normal env-var / built-in fallback
applies.

## Usage

``` r
.azr_defaults
```

## Format

An object of class `environment` of length 3.
