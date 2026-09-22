# Detect if running in a hosted session

Determines whether the current R session is running in a hosted
environment such as Google Colab, VS Code, Kubernetes, or RStudio Server
(non-localhost).

## Usage

``` r
is_hosted_session()
```

## Value

A logical value: `TRUE` if running in a hosted session (Google Colab, VS
Code, Kubernetes, or remote RStudio Server), `FALSE` otherwise.

## Details

This function checks for (in order):

- Option override: if `azr.hosted` option is set, returns
  [`isTRUE()`](https://rdrr.io/r/base/Logic.html) of its value

- Google Colab: presence of the `COLAB_RELEASE_TAG` environment variable

- VS Code: presence of the `VSCODE_INJECTION` or `VSCODE_PROXY_URI`
  environment variable

- Kubernetes: presence of the `KUBERNETES_SERVICE_HOST` environment
  variable

- RStudio Server: `RSTUDIO_PROGRAM_MODE` is "server" and
  `RSTUDIO_HTTP_REFERER` does not contain "localhost"

## Examples

``` r
if (is_hosted_session()) {
  message("Running in a hosted environment")
}
```
