# Code Review TODO

## Bugs

- [ ] **`default_response_handler` returns `NULL` for non-list/non-data.frame content** (`R/api-client.R:532-544`)
  When `data.table` is installed and the response content is not a `data.frame` or `list` (e.g. a raw string from a non-JSON endpoint), the function falls off the end and returns `NULL`. The list branch also returns invisibly due to the bare assignment. Fix by adding an explicit `return(content)` at the end of the function so all cases are covered.

- [ ] **`.redirect_uri` public field never locked** (`R/credential.R:19`, `R/credential.R:92-107`)
  Every public field in `Credential` is locked after `initialize()` via `lockBinding()` — except `.redirect_uri`. It is declared on line 19 but omitted from the lock block. Either lock it (consistent with the rest) or remove it from the base class if it is unused there.

- [ ] **`CachedTokenCredential` rejected by `api_client`** (`R/api-client.R:145-153`, `R/credential-cached-token.R`)
  The `provider` guard in `api_client$initialize()` only accepts objects that inherit from `Credential` or `DefaultCredential`. `CachedTokenCredential` inherits from neither, so passing it as `provider` throws an error. Fix by adding `"CachedTokenCredential"` to the `inherits()` check, or introduce a shared interface marker class that all three inherit from.

## Inconsistencies

- [ ] **`InteractiveCredential` public fields not locked** (`R/credential-interactive.R:16-19`)
  `use_refresh_token` and `interactive` are public fields added by `InteractiveCredential` but they are never locked — inconsistent with the pattern in the base `Credential` class. After `super$initialize()`, add `lockBinding("use_refresh_token", self)` and `lockBinding("interactive", self)`.

- [ ] **`credential_chain` defined twice — internal version is dead code** (`R/credential.R:145-149` vs `R/default-credential.R:672-687`)
  The unexported version in `credential.R` is silently overwritten by the exported one in `default-credential.R`. The internal version also lacks the empty-chain guard. Remove it from `credential.R`.

## New features

- [ ] **`ManagedIdentityCredential`**
  Authenticate using Azure managed identity (system-assigned or user-assigned) when running inside Azure (VM, App Service, Container Instances, AKS pod). Makes a single unauthenticated GET to the IMDS endpoint (`http://169.254.169.254/metadata/identity/oauth2/token`) — no signing or extra dependencies required. Should be added to `default_credential_chain()` between `ClientSecretCredential` and the interactive credentials.

- [ ] **`EnvironmentCredential`**
  A router credential that inspects environment variables and delegates to the appropriate underlying credential. Currently only meaningful for the `ClientSecretCredential` case (same env vars already read by that class), but becomes valuable once `CertificateCredential` is added — it would then route `AZURE_CLIENT_CERTIFICATE_PATH` to `CertificateCredential` and `AZURE_CLIENT_SECRET` to `ClientSecretCredential` automatically.

## Improvements

- [ ] **Logging in `api_client` is always-on** (`R/api-client.R:353-371`)
  The `verbosity` parameter only controls `httr2::req_perform()` verbosity. The `cli_alert_info(">>>")` and `cli_alert_success("<<<")` calls in `.send_request()` always fire. Gate them on `getOption("azr.verbose", FALSE)` (already used elsewhere in the package) so production pipelines can suppress them.

- [ ] **`new_instance()` cannot distinguish `NULL` from absent** (`R/default-credential.R:689-700`)
  Arguments explicitly set to `NULL` in the caller environment are silently dropped because `Filter(Negate(is.null), ...)` removes them, causing the class to use its own default instead of the caller's intent. Use a sentinel (e.g. `rlang::missing_arg()`) as the `default` in `env_get_list()` to distinguish "not found" from "explicitly NULL".

- [ ] **`use_cache` not validated upfront in `DefaultCredential`** (`R/default-credential.R:71`)
  `DefaultCredential$initialize()` stores `use_cache` without calling `rlang::arg_match()`, unlike `Credential$initialize()` (line 52 of `credential.R`). The value is only validated later when the underlying credential is constructed. Add an upfront `arg_match` for a better error message at construction time.
