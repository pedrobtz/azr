# Changelog

## azr 0.3.5

CRAN release: 2026-06-26

- Added
  [`azr_dataset()`](https://pedrobtz.github.io/azr/reference/azr_dataset.md),
  [`azr_catalog()`](https://pedrobtz.github.io/azr/reference/azr_catalog.md),
  and
  [`azr_resolve_dataset()`](https://pedrobtz.github.io/azr/reference/azr_resolve_dataset.md)
  for declaring and resolving Azure Storage datasets across environment
  tiers.
- Added
  [`azr_logs_client()`](https://pedrobtz.github.io/azr/reference/azr_logs_client.md)
  for running KQL queries against the Azure Log Analytics REST API.
- Added `ManagedIdentityCredential` for managed identity authentication
  via the IMDS endpoint.
- Added
  [`azr_options()`](https://pedrobtz.github.io/azr/reference/azr_options.md),
  an option registry backing the new `azr.*` options.
- Added
  [`azure_spark_storage_conf()`](https://pedrobtz.github.io/azr/reference/azure_spark_storage_conf.md)
  for generating Spark/Hadoop storage configuration keys, with
  sovereign-cloud support.
- Added
  [`parse_storage_path()`](https://pedrobtz.github.io/azr/reference/parse_storage_path.md)
  for splitting Azure Storage URIs, including `az://`/`azure://` schemes
  and sovereign-cloud endpoints.
- `api_client$new()` gained a `verbose` argument that gates request and
  response logging.
- [`azr_graph_client()`](https://pedrobtz.github.io/azr/reference/azr_graph_client.md)
  gained an `endpoint` argument so the Microsoft Graph host is no longer
  hardcoded.
- `api_storage_client` gained a `client_id` argument, and `list_files()`
  now pages through all results automatically.
- Breaking:
  [`get_credential_provider()`](https://pedrobtz.github.io/azr/reference/get_credential_provider.md)’s
  `interactive` argument is renamed to `allow_interactive`, and
  [`default_credential_chain()`](https://pedrobtz.github.io/azr/reference/default_credential_chain.md)
  now tries workload identity, managed identity, and Azure CLI ahead of
  interactive credentials.
- The base `Credential` class no longer aborts at construction in
  non-interactive sessions (deferred to
  [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)),
  and its shared configuration checks moved to a private
  `validate_base()` helper.
- `AzureCLICredential`’s `interactive` argument is renamed to
  `auto_login`, with login checked lazily in
  [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md).
- `InteractiveCredential` (and
  `AuthCodeCredential`/`DeviceCodeCredential`) renamed its `interactive`
  argument to `allow_prompt`.
- [`cached_token_credential_chain()`](https://pedrobtz.github.io/azr/reference/cached_token_credential_chain.md)
  was updated to the renamed `allow_prompt`/`auto_login` arguments.
- Internal: `ClientSecretCredential`’s `$validate()` now delegates to
  the shared `validate_base()` helper.
- Internal: `RefreshTokenCredential`’s `$validate()` now delegates to
  the shared `validate_base()` helper.
- `WorkloadIdentityCredential` now performs its required
  `tenant_id`/`client_id` checks in `$validate()` rather than its
  constructor body.
- [`default_azure_scope()`](https://pedrobtz.github.io/azr/reference/default_azure_scope.md)
  now accepts short service names without the `azure_` prefix.
- Internal `azure_services` replaces
  `azure_storage_endpoints`/`azure_scopes`, consolidating per-service
  OAuth hosts and data-plane endpoints.
- Added internal `list_redact_pattern()` for redacting named list
  entries by pattern.
- Added internal `validate_required_string()` and `deprecated_arg()`
  helpers.
- Added an `.onLoad()` hook that registers S7 methods via
  [`S7::methods_register()`](https://rconsortium.github.io/S7/reference/methods_register.html).
- Added namespace imports for the S7 `@` operator and rlang’s `:=`.

## azr 0.3.4

CRAN release: 2026-05-09

- Removed `set_azr_defaults()` that was announced in 0.3.3 but never
  shipped. The corresponding
  [`getOption()`](https://rdrr.io/r/base/options.html) reads in
  [`default_azure_host()`](https://pedrobtz.github.io/azr/reference/default_azure_host.md),
  [`default_azure_client_id()`](https://pedrobtz.github.io/azr/reference/default_azure_client_id.md),
  and
  [`default_azure_tenant_id()`](https://pedrobtz.github.io/azr/reference/default_azure_tenant_id.md)
  were also not implemented; use environment variables
  (`AZURE_AUTHORITY_HOST`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`)
  instead.
- `WorkloadIdentityCredential` now maintains an in-object token cache.
  Repeated calls to
  [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)
  return the cached token immediately without re-reading the federated
  token file or exchanging it, until the token expires.
- `AZURE_AUTHORITY_HOST` values with an `https://` scheme prefix (as
  recommended by the Azure SDK documentation) are now handled correctly.
  Previously, setting
  `AZURE_AUTHORITY_HOST=https://login.microsoftonline.com` would produce
  malformed token URLs
  ([\#16](https://github.com/pedrobtz/azr/issues/16)).

## azr 0.3.3

CRAN release: 2026-05-04

- Added `set_azr_defaults()` to configure package-level overrides for
  the authority host, client ID, and tenant ID. These take priority over
  environment variables in
  [`default_azure_host()`](https://pedrobtz.github.io/azr/reference/default_azure_host.md),
  [`default_azure_client_id()`](https://pedrobtz.github.io/azr/reference/default_azure_client_id.md),
  and
  [`default_azure_tenant_id()`](https://pedrobtz.github.io/azr/reference/default_azure_tenant_id.md).
- `AuthCodeCredential` and `DeviceCodeCredential` now maintain an
  in-object token cache keyed by scope. Repeated calls to
  [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)
  for the same scope return the cached token immediately without hitting
  the httr2 cache or refresh token flow.

## azr 0.3.2

CRAN release: 2026-03-30

- [`is_hosted_session()`](https://pedrobtz.github.io/azr/reference/is_hosted_session.md)
  now detects VS Code (`VSCODE_INJECTION`, `VSCODE_PROXY_URI`) and
  Kubernetes (`KUBERNETES_SERVICE_HOST`) environments, and supports an
  `azr.hosted` option override.
- Extracted internal `try_as_data_table()` helper from
  [`default_response_handler()`](https://pedrobtz.github.io/azr/reference/default_response_handler.md).

## azr 0.3.1

CRAN release: 2026-03-04

- Interactive credentials (`AuthCodeCredential`, `DeviceCodeCredential`)
  now attempt silent token acquisition via refresh token before
  prompting the user interactively.

## azr 0.3.0

CRAN release: 2026-02-17

- Added `azr_storage_client` interface to the Azure Storage API.
- Added `CachedTokenCredential` for non-interactive sessions that reuse
  previously cached tokens from `AuthCodeCredential` or
  `DeviceCodeCredential` without triggering a new authentication flow.
- Refactored `api_client$.fetch()`: `req_data` is now split into
  separate `query` and `body` arguments, `req_method` is renamed to
  `method`, a `headers` argument was added, and path interpolation now
  uses
  [`rlang::englue()`](https://rlang.r-lib.org/reference/englue.html)
  instead of
  [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html).

## azr 0.2.1

CRAN release: 2026-01-07

### New features

- Added `DefaultCredential` for simplified authentication using Azure’s
  default credential chain.

### Bug fixes and improvements

- Removed dependency on httpuv package.

## azr 0.2.0

CRAN release: 2025-12-04

### New features

- Added `api_client` R6 class providing a base HTTP client for Azure
  APIs with automatic authentication, retry logic, and error handling.
- Added `api_resource` and `api_services` classes for Azure Resource
  Manager interactions.
- Introduced custom credentials function support in API clients for
  flexible authentication.
- Added response handler callbacks to customize API response processing.

### Authentication improvements

- Enhanced credential chain with support for Azure CLI authentication.
- Added interactive authentication flows (Device Code and Auth Code).
- Improved client secret credential handling.
- Fixed authentication issues with auth-code flow.

### Bug fixes and improvements

- Fixed credential validation to properly check function objects in
  `api_client`.
- Fixed issues with Graph client authentication and request handling.
- Improved error messages and logging throughout the package.
- Added comprehensive tests for core functionality.
- Enhanced documentation with examples and usage guides.

## azr 0.1.0

CRAN release: 2025-11-04

- Initial CRAN submission.
