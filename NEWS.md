# azr (development version)

* Added S7 classes `az_dataset`, `az_catalog`, and `az_dataset_manifest` for declaring collections of Azure Storage datasets and sharing resolved dataset metadata with external packages, along with `az_dataset_from_uri()`, `az_catalog_read()`, `az_catalog_write()`, `az_dataset_uri()`, and `az_dataset_resolve()`. A catalog supports `[[`, `names()`, and `length()`, and `az_dataset_uri()`/`az_dataset_resolve()` dispatch on both `az_dataset` and `az_catalog` (with an optional `name` to look up a single dataset). `az_dataset_resolve()` returns typed manifests containing the `name`, `uri`, and `format`, e.g. for use with `sparklyr::spark_read_source()`. The `format` field accepts `delta`, `parquet`, `csv`, `tsv`, `json`, `avro`, `orc`, or `text`; `az_dataset_from_uri()` infers it from the URI when possible and errors with guidance when the URI is a directory. The default `tier` for `az_dataset_uri()`, `az_dataset_resolve()`, and `az_dataset_from_uri()` is controlled by the new `dataset_tier` option (`options(azr.dataset_tier = ...)` or `AZR_DATASET_TIER`, default `"prod"`). Adds `S7` to Imports.
* `api_client$new()` gained a `verbose` argument that gates the `>>>` request and `<<<` response `cli` alerts in `.send_request()`. Defaults to `azr_opt("api_verbose")` (R option `azr.api_verbose` or env var `AZR_API_VERBOSE`); previously these alerts were always on.
* The `verbose` argument of `get_credential_provider()` now defaults to `azr_opt("chain_verbose")` (R option `azr.chain_verbose` or env var `AZR_CHAIN_VERBOSE`), replacing the prior `azr.verbose` / `AZR_VERBOSE` option.
* Added `default_graph_endpoint()` and an `endpoint` argument to `azr_graph_client()` so the Microsoft Graph host is no longer hardcoded. Service metadata (resource host and data-plane endpoints) is now consolidated in a single internal `azure_services` list, and `default_azure_scope()` derives the `/.default` scope from the resource host.
* Added `api_log_analytics_client` and `azr_logs_client()` for running KQL queries against the Azure Log Analytics REST API. The client binds to a `subscription_id` and `resource_id` (resource group) at construction and exposes a `$query()` method that POSTs the KQL query as JSON; the `tables` response is parsed into one or more `data.frame`s.
* Added `ManagedIdentityCredential` for Azure managed identity authentication (system- or user-assigned) via the IMDS endpoint. `default_credential_chain()` now includes `WorkloadIdentityCredential` and `ManagedIdentityCredential`, and places `AzureCLICredential` before interactive credentials.
* Breaking: `azure_spark_storage_conf()` parameters renamed (`type` → `auth_type`, `storage` → `storage_account`, `oauth_host` → `authority_host`), default `auth_type` changed to `"refresh_token"`, and output now prefixed with `spark.hadoop.` by default (`prefix = NULL` for raw `fs.azure.*` keys). Added `"managed_identity"` and `"shared_key"` auth types, sovereign cloud support, and several bug fixes. The returned list now has a `print()` method that redacts secrets.
* `parse_storage_path()` now accepts `az://` and `azure://` schemes, captures a new `endpoint_suffix` field for sovereign cloud detection, handles DNS-zone endpoints, and redacts SAS credentials in `print()`.
* `default_azure_scope()` now accepts short names without the `azure_` prefix (e.g. `"storage"`). New scopes added: `azure_log_analytics`, `azure_app_insights`, `azure_databricks`, `azure_sql`, `azure_service_bus`.
* Fixed `get_credential_provider()` constructing chain entries by scraping local variables out of its own execution frame by name. Constructors now receive an explicit context (`scope`, `tenant_id`, `client_id`, `client_secret`, `use_cache`, `offline`, `oauth_host`, `oauth_endpoint`), matched against each credential's `initialize()` formals. `interactive` is no longer part of this context: it is chain-runner policy, not a constructor argument, so it can no longer leak into `AzureCLICredential` and override its `cli_auto_login` default with an unsolicited `az login`.
* Breaking: `credential_chain()` is now eager. Entries are validated and normalized to `azr_credential_spec` objects (or used as-is for pre-built `Credential` instances) at definition time, instead of being captured as quosures and evaluated on first use. Constructing a chain now performs no authentication side effects. Added `credential_spec(class, ...)` for chain entries that need per-entry constructor arguments overriding the provider's context (entry arguments take precedence, then provider context, then the constructor's own defaults); unknown or unnamed `credential_spec()` arguments error immediately. Both `credential_chain` and `azr_credential_spec` objects have `print()`/`format()` methods that redact sensitive constructor arguments (matching `secret|token|password|key`).
* Constructors no longer have authentication side effects. `AzureCLICredential$new()` no longer checks `az login` status or runs `az login` at construction time (moved to `get_token()`/`req_auth()`), and credential constructors no longer abort when called from a non-interactive session (moved to `get_token()`, which now reports "requires an interactive session" if no cached or refreshable token is available).
* Several arguments related to interactivity have been renamed for clarity, with the old names deprecated for one release: `get_credential_provider(interactive = )` is now `allow_interactive = `; `AzureCLICredential$new(interactive = )` is now `auto_login = `; and `InteractiveCredential`/`AuthCodeCredential`/`DeviceCodeCredential`'s `interactive = ` argument is now `allow_prompt = `. `cached_token_credential_chain()` and `CachedTokenCredential` have been updated to use the new names.

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
