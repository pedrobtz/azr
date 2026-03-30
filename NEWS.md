# azr

# azr 0.3.2

* `is_hosted_session()` now detects VS Code (`VSCODE_INJECTION`, `VSCODE_PROXY_URI`) and Kubernetes (`KUBERNETES_SERVICE_HOST`) environments, and supports an `azr.hosted` option override.
* Extracted internal `try_as_data_table()` helper from `default_response_handler()`.

# azr 0.3.1

* Interactive credentials (`AuthCodeCredential`, `DeviceCodeCredential`) now attempt silent token acquisition via refresh token before prompting the user interactively.

# azr 0.3.0

* Added `azr_storage_client` interface to the Azure Storage API.
* Added `CachedTokenCredential` for non-interactive sessions that reuse previously cached tokens from `AuthCodeCredential` or `DeviceCodeCredential` without triggering a new authentication flow.
* Refactored `api_client$.fetch()`: `req_data` is now split into separate `query` and `body` arguments, `req_method` is renamed to `method`, a `headers` argument was added, and path interpolation now uses `rlang::englue()` instead of `glue::glue()`.

# azr 0.2.1

## New features

* Added `DefaultCredential` for simplified authentication using Azure's default credential chain.

## Bug fixes and improvements

* Removed dependency on httpuv package.

# azr 0.2.0

## New features

* Added `api_client` R6 class providing a base HTTP client for Azure APIs with automatic authentication, retry logic, and error handling.
* Added `api_resource` and `api_services` classes for Azure Resource Manager interactions.
* Introduced custom credentials function support in API clients for flexible authentication.
* Added response handler callbacks to customize API response processing.

## Authentication improvements

* Enhanced credential chain with support for Azure CLI authentication.
* Added interactive authentication flows (Device Code and Auth Code).
* Improved client secret credential handling.
* Fixed authentication issues with auth-code flow.

## Bug fixes and improvements

* Fixed credential validation to properly check function objects in `api_client`.
* Fixed issues with Graph client authentication and request handling.
* Improved error messages and logging throughout the package.
* Added comprehensive tests for core functionality.
* Enhanced documentation with examples and usage guides.

# azr 0.1.0

* Initial CRAN submission.
