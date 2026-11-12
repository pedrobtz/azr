# CLAUDE.md

<!-- markdownlint-disable-next-line MD013 -->
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Shared conventions

The portfolio's shared rules are synced into `.claude/shared/` from
`pedrobtz/packages:claude/shared/`. Never edit them here. Where this file and
a shared file disagree, this file wins for this package.

@.claude/shared/workflow.md
@.claude/shared/r-package.md
@.claude/shared/ci.md
@.claude/shared/correctness.md
@.claude/shared/assurance.md

## What this is

azr implements a credential chain for Azure OAuth 2.0, built on httr2's OAuth
framework. It sequentially attempts authentication methods until one succeeds,
so the same code authenticates from a laptop, a CI runner and an AKS pod. On
top of that sits a thin HTTP client layer (`api_client` / `api_resource` /
`api_service`) that service wrappers such as `AzureGraphClient` and
`AzureStorageClient` are built from.

The package acquires tokens and authorizes requests. It is not an Azure SDK:
there is no ambition to wrap every Azure service, and a new service wrapper
belongs here only when it exercises the credential layer.

**Dependency stance.** Hard dependencies stay at the current set (`httr2`,
`cli`, `rlang`, `R6`, `S7`, `jsonlite`, `utils`), a deliberate deviation from
the zero-dependency default in `.claude/shared/r-package.md`. Everything else
is a Suggest and every code path that touches one must work without it — see
the invariant below.

Three documents in `.dev/` outrank this file on their own subjects:
`.dev/AGENTS.md` (working agreement and the NEWS entry rules),
`.dev/TODO.md` (known defects and roadmap, with file:line references) and
`.dev/moniker.md` (design for consolidating the storage interfaces). **`.dev/`
is gitignored**, so those files live only in a working copy — read them when
they are present, and do not assume a fresh clone has them. azr has no
`.agents/` directory.

## Current state

Verified 2026-11-12. `devtools::test()` and `devtools::test(shuffle = TRUE)`
are both green: 866 passing, 0 failures, 24 skipped. Every skip requires an
interactive session or a live `az login`; a local run with 24 skips is the
expected result, not a problem to fix. Helpers shared between test blocks live
in `tests/testthat/helper-*.R`.

Verified 2026-11-11: 0.3.6 is on CRAN, published 2026-09-22, and `main` is
`0.3.6.9000`.

Not implemented, as opposed to broken: `EnvironmentCredential` and
`CertificateCredential`. Known and deliberate-for-now defects, each with a
file:line reference in `.dev/TODO.md`: `AzureCLICredential` has no in-object
token cache and shells out to `az` on every call, and `new_instance()` cannot
distinguish an explicit `NULL` from an absent argument.

## Versions and dependents

The current version's parent issue is
[`#33`](https://github.com/pedrobtz/azr/issues/33) for `v0.3.7`. Sibling
packages that depend on this one: none recorded.

azr has no `cran-release.yaml`, so the `.9000` bump after a release is made by
hand rather than arriving as a pull request: bump to `x.y.z.9000` after a
release, and drop the suffix when cutting the next one. Retitle the
`# azr (development version)` NEWS heading to the release number at that
point.

## Commands

Run from the package root. Always invoke R with `--quiet --vanilla`; that and
the arguments below override the shared commands.

```sh
Rscript --quiet --vanilla -e 'devtools::load_all()'
Rscript --quiet --vanilla -e 'devtools::document()'
Rscript --quiet --vanilla -e 'devtools::test(reporter = "check")'
Rscript --quiet --vanilla -e 'devtools::test(filter = "azure-cli")'
Rscript --quiet --vanilla -e 'devtools::test(shuffle = TRUE)'
Rscript --quiet --vanilla -e 'devtools::check(error_on = "warning")'
Rscript --quiet --vanilla -e 'pkgdown::check_pkgdown()'
Rscript --quiet --vanilla -e 'lintr::lint_package()'
air format .
```

Run `pkgdown::check_pkgdown()` after adding a documentation topic, and
`air format .` after generating any R code.

`devtools::test()` is the development loop; it is fast enough to run on every
change. `check()` and `pkgdown::check_pkgdown()` are release-gate commands.

**Check the roxygen2 version before documenting.** `DESCRIPTION` records
`Config/roxygen2/version: 8.0.0`. A different roxygen2 major version
regenerates every file under `man/`, producing a diff of about 30 files that
has nothing to do with the change in hand. Raise a roxygen2 change as its own
piece of work; do not let it ride along in an unrelated commit.

## Architecture

**Credential layer.** `Credential` (`R/credential.R`) is the R6 base class;
each implementation is one `R/credential-*.R` file. `credential_chain()` and
`default_credential_chain()` (`R/default-credential.R`) describe an ordered
list of candidates, and `get_credential_provider()` walks it and returns the
first credential that actually produces a token. `get_token()`,
`get_user_token()`, `get_token_provider()`, `get_request_authorizer()` and
`get_credential_auth()` are wrappers over that one walk.

**HTTP layer.** `api_client` (`R/api-client.R`) holds auth, retry/backoff,
logging and content handling; `.fetch()` is the single request method and
interpolates its `path` with `rlang::englue()`, so `"/order/{order_id}"` picks
up an `order_id` argument. `api_resource` adds a fixed path prefix,
`api_service` groups named resources.

**Dataset layer.** `R/azr-dataset.R` is the only S7 code in the package
(`azr_dataset`, `azr_catalog`, and the `azr_dataset_uri` /
`azr_resolve_dataset` generics). Everything else is R6.

**Configuration.** `R/options.R` holds a small option registry resolved in the
order: value set via `opts$set()`, then `options(azr.*)`, then the environment
variable, then the built-in default. `R/constants.R` holds the scope and
authority-host tables. `az_config()` reports what the credential layer will
actually see.

## Invariants that are easy to break

- **A `Credential`'s public fields are locked after `initialize()`** via
  `lockBinding()`. Mutating one errors at runtime; construct a new credential
  instead. `CachedTokenCredential` and `DefaultCredential` do not yet lock
  theirs — that is a recorded inconsistency in `.dev/TODO.md`, not licence to
  rely on mutability.
- **Chain entries are quosures, evaluated late.** `credential_chain()` captures
  with `rlang::enquos()` and `eval_chain_entry()` evaluates against a data mask
  cloning the azr namespace, which is what lets a bare `ClientSecretCredential`
  resolve when the package is not attached. Forcing entries eagerly breaks that.
- **`new_instance()` forwards only context names that match the class's
  `initialize()` formals.** A credential silently never receives context it
  does not declare as an argument — the symptom is a default quietly winning,
  with no error.
- **`build_credential_context()` drops `NULL`s and deliberately excludes
  `interactive`.** Interactivity is chain-runner policy in
  `try_build_credential()`, not a constructor argument; passing it down would
  override a credential's own defaults, such as `AzureCLICredential`'s
  `cli_auto_login`.
- **The order of `default_credential_chain()` is a semantic decision, not a
  preference.** `workload_identity` and `managed_identity` come before
  `azure_cli`, so on a host configured for a service identity `get_token()`
  returns the *workload's* token even with a person at the console. That is why
  `get_user_token()` exists. Reordering silently changes who a token belongs to.
- **A Suggests package must degrade, never prompt.** Guard with
  `rlang::is_installed()` and skip the optional step. `rlang::check_installed()`
  interrupts a login flow to ask about an install, which is the wrong thing to
  do mid-authentication.
- **Nothing that prints configuration may print a secret.** `Credential$print()`
  redacts through `list_redact()` and `az_config()` reports
  `AZURE_CLIENT_SECRET` as redacted. Any new surface that reports config must
  do the same.
- **`.onAttach()` renders `format_az_config()`.** An error in that path makes
  the package fail to attach, so it must tolerate any environment.
- **S7 methods need `S7::methods_register()` in `.onLoad()`.** New S7 generics
  or methods only dispatch because of that call.
- **A new top-level file needs an `.Rbuildignore` entry** or `R CMD check`
  raises a NOTE for a non-standard file at the package root.

## Testing

- Tests for `R/{name}.R` live in `tests/testthat/test-{name}.R`.
- **No live Azure calls.** HTTP-layer tests replay vcr cassettes from
  `tests/testthat/_vcr/`, recorded against the public Swagger Petstore rather
  than Azure, so they exercise `api_client` without credentials.
- The package raises classed conditions such as
  `azr_credential_chain_failed`, `azr_cli_not_logged_in`,
  `azr_cli_timeout_error` and `azr_requires_interactive_session`; assert on
  those.
- **Isolate the environment.** These tests read the same `AZURE_*` variables as
  production code; set them through `withr::local_envvar()`. A test that reads a
  variable it did not set will pass or fail depending on whose laptop it runs
  on.
- Gate on capability, not platform: `skip_if_not(rlang::is_interactive())`,
  `skip_if_not_installed("httpuv")`, `skip_if_not(nzchar(Sys.which("az")))`.
- `tests/testthat/helper-resource.R` defines the `api_store_resource` subclass
  that the `api_resource` and `api_service` tests build on.
- Keep the suite near its current ~11 seconds.

## Definition of done, beyond the shared one

`devtools::check(error_on = "warning")` is the check, and `air format .` has
been run. `devtools::test(shuffle = TRUE)` must be green.

NEWS bullets are one line, present tense, positively framed, with the function
name in backticks near the start, and the issue number before the final period:
`` * `fn()` now accepts ... (@user, #N). ``. **Never invent an issue number** —
take it from the prompt, the branch name or `gh issue list`, and use
`#noissue` if there is none.

## Editing rules, beyond the shared ones

- A new documentation topic goes into `_pkgdown.yml`, verified with
  `pkgdown::check_pkgdown()`.
- Errors use `cli::cli_abort()` with a condition class, following tidyverse
  style.
- Newspaper style: main logic at the top, helpers below. Avoid defining
  functions inside functions.
- Comments explain why, not what. Sentence case for headings.

When you find a defect, in this package or upstream, record it in
`.dev/TODO.md` with a file:line reference or open an issue, rather than only
working around it.

## Continuous integration

Workflows live in `.github/workflows/`. `R-CMD-check.yaml`, `coverage.yaml` and
`pkgdown.yaml` call the shared `pedrobtz/r-actions` workflows, copied from its
`examples/` and gated by the CI labels in `.claude/shared/ci.md`: R CMD check
runs one Ubuntu R-release check on pull requests and the full runner matrix
on the weekly schedule, on dispatch and under `full-ci`; the CRAN-compiler
containers are turned off because azr has no compiled code. Coverage
commits its badge to `badges/coverage.svg` on gh-pages, and holds a write token,
so it is pinned to a commit SHA rather than `@v1`. Every workflow calls
r-actions; there are no hand-rolled ones. Lint locally with
`lintr::lint_package()`.
