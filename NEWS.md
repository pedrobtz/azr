# azr (development version)

* Added S7 classes `az_dataset` and `az_catalog`, plus `az_dataset_uri()`, `az_resolve_dataset()`, `az_dataset_from_uri()`, `az_catalog_read()`, and `az_catalog_write()` for declaring and resolving Azure Storage datasets across tiers. `az_resolve_dataset()` returns a plain list with `name`, `uri`, and `format`.
* Added the `azr.*` option registry (`azr_options()`, `opts$get`/`opts$set`) backing the new `chain_verbose`, `api_verbose`, `cli_auto_login`, and `dataset_tier` options.
* `api_client$new()` gained a `verbose` argument, defaulting to the `api_verbose` option, that gates the `>>>`/`<<<` request and response logging.
* Added `default_graph_endpoint()` and an `endpoint` argument to `azr_graph_client()` so the Microsoft Graph host is no longer hardcoded.
* Added `api_log_analytics_client` and `azr_logs_client()` for running KQL queries against the Azure Log Analytics REST API.
* Added `ManagedIdentityCredential` for Azure managed identity authentication via the IMDS endpoint, now included in `default_credential_chain()`.
* `default_azure_scope()` now accepts short service names without the `azure_` prefix and `default_credential_chain()` reorders and extends its entries to include workload identity, managed identity, and Azure CLI ahead of interactive credentials.
* Consolidated `azure_storage_endpoints`/`azure_scopes` into a single internal `azure_services` list of per-service OAuth resource hosts and data-plane endpoints.
* Added `azure_spark_storage_conf()` for generating Spark/Hadoop configuration keys (prefixed `spark.hadoop.` by default) for `refresh_token`, `client_secret`, `managed_identity`, and `shared_key` authentication, with sovereign cloud support.
* `parse_storage_path()` now accepts `az://`/`azure://` schemes, captures an `endpoint_suffix` for sovereign clouds, and handles DNS-zone endpoints.
* Breaking: `credential_chain()` accepts credential classes or configured credential instances, captured lazily and resolved when each entry is tried; `get_credential_provider()` builds class entries from an explicit context instead of scraping its caller's frame; renamed `get_credential_provider(interactive = )` to `allow_interactive = `.
* Credential classes validate their configuration at construction via `$validate()`, so an incompletely configured credential fails fast rather than at token time.
* Removed the constructor-time interactive-session check and unused `.redirect_uri` field from the base `Credential` class, and added an internal `is_credential()` helper.
* `AzureCLICredential` no longer checks or runs `az login` at construction; its `interactive` argument is renamed to `auto_login` (defaulting to the `cli_auto_login` option) and login is now checked lazily in `get_token()`.
* `InteractiveCredential`/`AuthCodeCredential`/`DeviceCodeCredential`'s `interactive` argument is renamed to `allow_prompt`, and constructors no longer abort in non-interactive sessions (deferred to `get_token()`).
* `cached_token_credential_chain()` and `CachedTokenCredential` are updated to use the renamed `allow_prompt`/`auto_login`/`allow_interactive` arguments.
* `api_storage_client$new()` gained a `client_id` argument, and `list_files()` now pages through all results automatically.

# azr 0.3.4

* Removed `set_azr_defaults()` that was announced in 0.3.3 but never shipped. The corresponding `getOption()` reads in `default_azure_host()`, `default_azure_client_id()`, and `default_azure_tenant_id()` were also not implemented; use environment variables (`AZURE_AUTHORITY_HOST`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`) instead.
* `WorkloadIdentityCredential` now maintains an in-object token cache. Repeated calls to `get_token()` return the cached token immediately without re-reading the federated token file or exchanging it, until the token expires.
* `AZURE_AUTHORITY_HOST` values with an `https://` scheme prefix (as recommended by the Azure SDK documentation) are now handled correctly. Previously, setting `AZURE_AUTHORITY_HOST=https://login.microsoftonline.com` would produce malformed token URLs (#16).

# azr 0.3.3

* Added `set_azr_defaults()` to configure package-level overrides for the authority host, client ID, and tenant ID. These take priority over environment variables in `default_azure_host()`, `default_azure_client_id()`, and `default_azure_tenant_id()`.
* `AuthCodeCredential` and `DeviceCodeCredential` now maintain an in-object token cache keyed by scope. Repeated calls to `get_token()` for the same scope return the cached token immediately without hitting the httr2 cache or refresh token flow.

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
