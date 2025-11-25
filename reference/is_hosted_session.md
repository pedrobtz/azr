# Detect if running in a hosted session

Determines whether the current R session is running in a hosted
environment such as Google Colab or RStudio Server (non-localhost).

## Usage

``` r
is_hosted_session()
```

## Value

A logical value: `TRUE` if running in a hosted session (Google Colab or
remote RStudio Server), `FALSE` otherwise.

## Details

This function checks for:

- Google Colab: presence of the `COLAB_RELEASE_TAG` environment variable

- RStudio Server: `RSTUDIO_PROGRAM_MODE` is "server" and
  `RSTUDIO_HTTP_REFERER` does not contain "localhost"

## Examples

``` r
if (is_hosted_session()) {
  message("Running in a hosted environment")
}
```
