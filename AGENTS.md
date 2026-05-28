# AGENTS.md

## Repository overview

**azr** — Credential Chain for Seamless 'OAuth 2.0' Authentication to 'Azure Services'

Implements a credential chain for 'Azure OAuth 2.0' authentication
based on the package 'httr2''s 'OAuth' framework. Sequentially attempts authentication
methods until one succeeds. During development allows interactive
browser-based flows ('Device Code' and 'Auth Code' flows) and non-interactive
flow ('Client Secret') in batch mode.

https://pedrobtz.github.io/azr/, https://github.com/pedrobtz/azr

### Overall structure

The project follows standard R package conventions with these key directories:

```
azr/
├── R/                          # R source code
│   ├── azr-package.R           # Auto-generated package docs
│   └── *.R                     # Function definitions, 1 file ~= 1 exported function
├── .github/
│   ├── ISSUE_TEMPLATE/         # GitHub issue templates
│   ├── skills/                 # Agent skill definitions
│   └── workflows/              # CI/CD configurations
├── tests/testthat/             # Test suite
│   └── _vcr/                   # VCR cassettes (mocked HTTP requests)
├── man/                        # Generated documentation (never edit directly)
├── AGENTS.md                   # This file
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Auto-generated export information
├── NEWS.md                     # Changelog
└── _pkgdown.yml                # pkgdown reference index
```

---

## Architecture

### Credential system

R6 class hierarchy for Azure OAuth 2.0 authentication:

- `Credential` (`R/credential.R`) — Abstract base class. Locks all public fields after `initialize()`.
- `DefaultCredential` (`R/default-credential.R`) — Lazily initialises a provider on first access using the default credential chain.
- `credential_chain()` / `default_credential_chain()` — Ordered list of credential classes to try in sequence.
- `get_credential_provider()` — Walks the chain; returns the first credential that successfully gets a token.
- `get_token_provider()`, `get_request_authorizer()`, `get_token()`, `get_credential_auth()` — Convenience wrappers.

**Credential implementations** (each in `R/credential-*.R`):

| Class | File | Notes |
|---|---|---|
| `ClientSecretCredential` | `R/credential-client-secret.R` | Non-interactive; uses env vars |
| `AuthCodeCredential` | `R/credential-interactive.R` | Browser-based; requires `httpuv` |
| `DeviceCodeCredential` | `R/credential-interactive.R` | Device code flow |
| `AzureCLICredential` | `R/credential-azure-cli.R` | Delegates to `az` CLI |
| `RefreshTokenCredential` | `R/credential-refresh-token.R` | Uses `AZURE_REFRESH_TOKEN` |
| `CachedTokenCredential` | `R/credential-cached-token.R` | Disk/memory cache |

### HTTP client layer

Base classes for building Azure API wrappers:

- `api_client` (`R/api-client.R`) — Base HTTP client with auth, retry/backoff, and logging. `.fetch()` is the main request method; supports path interpolation via `rlang::englue()`.
- `api_resource` (`R/api-resource.R`) — Extends `api_client` with a fixed path prefix (e.g. `"v1.0"`, `"beta"`).
- `api_service` (`R/api-services.R`) — Base class for service-specific wrappers; holds a client and named endpoint resources.

Pre-built clients: `AzureGraphClient` (`R/azure-graph-client.R`), `AzureStorageClient` (`R/azure-storage-client.R`).

### Key design patterns

- **R6 with locked bindings**: Fields are locked after `initialize()` via `lockBinding()`. Do not mutate after construction.
- **Credential chain**: `credential_chain()` captures unevaluated expressions via `rlang::enquos()`. `get_credential_provider()` evaluates each lazily.
- **`new_instance()` introspection**: Reads `initialize()` argument names and pulls matching names from the caller environment, allowing automatic forwarding of `scope`, `tenant_id`, etc.
- **Response handler**: `api_client` applies a `response_handler` callback to parsed JSON; the default converts `data.frame` to `data.table` when available.
- **Path interpolation**: `api_client$.fetch()` path strings are interpolated with `rlang::englue()`, e.g. `"/subscriptions/{subscription_id}/resourceGroups"`.

### Configuration

Environment variables: `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_AUTHORITY_HOST`, `AZURE_REFRESH_TOKEN`, `AZURE_CONFIG_DIR`.

Built-ins in `R/constants.R`: `azure_scopes` (`azure_arm`, `azure_graph`, `azure_storage`, `azure_key_vault`, `azure_openai`), `azure_authority_hosts` (`azure_public_cloud`, `azure_government`, `azure_china`). Default client ID is Microsoft's public Azure CLI client.

---

## Standard workflow

For any feature, fix, or refactor:

1. **Update packages**: `pak::pak()`
2. **Run tests** — confirm passing before changes: `devtools::test(reporter = "check")`. If any fail, stop and ask.
3. **Plan** — identify affected R files; check if new exports are needed.
4. **Test first** — write failing test, then implement: `devtools::test(filter = "name", reporter = "check")`.
5. **Implement** — minimal code to pass tests.
6. **Refactor** — clean up, keep tests green.
7. **Document** — run `devtools::document()` after any roxygen2 changes.
8. **Verify**: Run `devtools::test(reporter = "check")`, then `devtools::check(error_on = "warning")`. Resolve all warnings, errors, and NOTEs.
9. **News** — add bullet at top of `NEWS.md` (under dev heading):
   - User-facing changes only. 1 line, end with `.`
   - Present tense, positive framing, function names (backticks + `()`) near start: `` * `fn()` now accepts ... `` not `* Fixed ...`
   - Issue/contributor before final period: `` * `fn()` now accepts ... (@user, #N). `` where `#N` is the GitHub issue number.
   - Get username: `gh api user --jq .login`; get issue number from the user's prompt, the branch name (`git branch --show-current`), or `gh issue list`.
   - **Never guess or invent an issue number.** Before writing it, verify: (1) received from user or branch name, OR (2) looked up with `gh`. If untraceable, use `#noissue`.

---

## General

- R console: always use `--quiet --vanilla`.
- Always run `air format .` after generating R code.
- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`.
- Tests use VCR cassettes to mock HTTP — avoid live API calls.
- Never edit `.Rd` files directly; they are generated by roxygen2.
- Never edit `NAMESPACE` directly; it is generated by `devtools::document()`.
- Every user-facing function must be exported with roxygen2 docs.
- When adding a new documentation topic, add it to `_pkgdown.yml` and verify with `pkgdown::check_pkgdown()`.
- Use sentence case for all headings.
- Use newspaper style: main logic at the top, helpers below. Avoid defining functions inside functions.
- Error messages use `cli::cli_abort()` following the tidyverse style guide.
- Comments explain *why*, not *what*.
