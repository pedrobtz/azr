# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this is

azr implements a credential chain for Azure OAuth 2.0, built on httr2’s
OAuth framework. It sequentially attempts authentication methods until
one succeeds, so the same code authenticates from a laptop, a CI runner
and an AKS pod. On top of that sits a thin HTTP client layer
(`api_client` / `api_resource` / `api_service`) that service wrappers
such as `AzureGraphClient` and `AzureStorageClient` are built from.

The package acquires tokens and authorizes requests. It is not an Azure
SDK: there is no ambition to wrap every Azure service, and a new service
wrapper belongs here only when it exercises the credential layer.

**Dependency stance.** Hard dependencies stay at the current set
(`httr2`, `cli`, `rlang`, `R6`, `S7`, `jsonlite`, `utils`). Everything
else is a Suggest and every code path that touches one must work without
it — see the invariant below.

Three documents in `.dev/` outrank this file on their own subjects:
`.dev/AGENTS.md` (working agreement and the NEWS entry rules),
`.dev/TODO.md` (known defects and roadmap, with <file:line> references)
and `.dev/moniker.md` (design for consolidating the storage interfaces).
**`.dev/` is gitignored**, so those files live only in a working copy —
read them when they are present, and do not assume a fresh clone has
them.

## Current state

Verified 2026-09-22. `devtools::test()` is green: 769 passing, 0
failures, 24 skipped, about 11 seconds. Every skip requires an
interactive session or a live `az login`; a local run with 24 skips is
the expected result, not a problem to fix.

`devtools::test(shuffle = TRUE)` is **not** green: 11 failures, all in
`tests/testthat/test-workload-identity.R`, which defines the file-scope
helpers `new_wi_cred()` and `wi_inject_token()` that shuffled blocks run
ahead of. This is a defect in that test file, not in the package, and
not a reason to stop treating shuffled runs as the standard — fix the
file.

Released on CRAN at 0.3.5; the working tree is 0.3.6.

Not implemented, as opposed to broken: `EnvironmentCredential` and
`CertificateCredential`. Known and deliberate-for-now defects, each with
a <file:line> reference in `.dev/TODO.md`: `AzureCLICredential` has no
in-object token cache and shells out to `az` on every call, and
`new_instance()` cannot distinguish an explicit `NULL` from an absent
argument.

## Versioning

azr is released, so it follows the `.9000` development convention: bump
to `x.y.z.9000` after a release, and drop the suffix when cutting the
next one. Retitle the `# azr (development version)` NEWS heading to the
release number at that point.

## Commands

Run from the package root. Always invoke R with `--quiet --vanilla`.

``` sh
Rscript --quiet --vanilla -e 'devtools::load_all()'
Rscript --quiet --vanilla -e 'devtools::document()'              # roxygen -> NAMESPACE, man/
Rscript --quiet --vanilla -e 'devtools::test(reporter = "check")'
Rscript --quiet --vanilla -e 'devtools::test(filter = "azure-cli")'   # one test file
Rscript --quiet --vanilla -e 'devtools::test(shuffle = TRUE)'
Rscript --quiet --vanilla -e 'devtools::check(error_on = "warning")'
Rscript --quiet --vanilla -e 'pkgdown::check_pkgdown()'          # after adding a doc topic
Rscript --quiet --vanilla -e 'lintr::lint_package()'
air format .                                                      # after generating any R code
```

`devtools::test()` is the development loop; it is fast enough to run on
every change. `check()` and
[`pkgdown::check_pkgdown()`](https://pkgdown.r-lib.org/reference/check_pkgdown.html)
are release-gate commands.

**Check the roxygen2 version before documenting.** `DESCRIPTION` records
`RoxygenNote: 7.3.3`. roxygen2 8.0.0 regenerates every file under `man/`
and migrates that field to `Config/roxygen2/version`, producing a
~30-file diff that has nothing to do with the change in hand. If the
installed roxygen2 is 8.x, either install 7.3.3 or raise the upgrade as
its own piece of work — do not let it ride along in an unrelated commit.

## Architecture

**Credential layer.** `Credential` (`R/credential.R`) is the R6 base
class; each implementation is one `R/credential-*.R` file.
[`credential_chain()`](https://pedrobtz.github.io/azr/dev/reference/credential_chain.md)
and
[`default_credential_chain()`](https://pedrobtz.github.io/azr/dev/reference/default_credential_chain.md)
(`R/default-credential.R`) describe an ordered list of candidates, and
[`get_credential_provider()`](https://pedrobtz.github.io/azr/dev/reference/get_credential_provider.md)
walks it and returns the first credential that actually produces a
token.
[`get_token()`](https://pedrobtz.github.io/azr/dev/reference/get_token.md),
[`get_user_token()`](https://pedrobtz.github.io/azr/dev/reference/get_user_token.md),
[`get_token_provider()`](https://pedrobtz.github.io/azr/dev/reference/get_token_provider.md),
[`get_request_authorizer()`](https://pedrobtz.github.io/azr/dev/reference/get_request_authorizer.md)
and
[`get_credential_auth()`](https://pedrobtz.github.io/azr/dev/reference/get_credential_auth.md)
are wrappers over that one walk.

**HTTP layer.** `api_client` (`R/api-client.R`) holds auth,
retry/backoff, logging and content handling; `.fetch()` is the single
request method and interpolates its `path` with
[`rlang::englue()`](https://rlang.r-lib.org/reference/englue.html), so
`"/order/{order_id}"` picks up an `order_id` argument. `api_resource`
adds a fixed path prefix, `api_service` groups named resources.

**Dataset layer.** `R/azr-dataset.R` is the only S7 code in the package
(`azr_dataset`, `azr_catalog`, and the `azr_dataset_uri` /
`azr_resolve_dataset` generics). Everything else is R6.

**Configuration.** `R/options.R` holds a small option registry resolved
in the order: value set via `opts$set()`, then `options(azr.*)`, then
the environment variable, then the built-in default. `R/constants.R`
holds the scope and authority-host tables.
[`az_config()`](https://pedrobtz.github.io/azr/dev/reference/az_config.md)
reports what the credential layer will actually see.

## Invariants that are easy to break

- **A `Credential`’s public fields are locked after `initialize()`** via
  [`lockBinding()`](https://rdrr.io/r/base/bindenv.html). Mutating one
  errors at runtime; construct a new credential instead.
  `CachedTokenCredential` and `DefaultCredential` do not yet lock theirs
  — that is a recorded inconsistency in `.dev/TODO.md`, not licence to
  rely on mutability.
- **Chain entries are quosures, evaluated late.**
  [`credential_chain()`](https://pedrobtz.github.io/azr/dev/reference/credential_chain.md)
  captures with
  [`rlang::enquos()`](https://rlang.r-lib.org/reference/enquo.html) and
  `eval_chain_entry()` evaluates against a data mask cloning the azr
  namespace, which is what lets a bare `ClientSecretCredential` resolve
  when the package is not attached. Forcing entries eagerly breaks that.
- **`new_instance()` forwards only context names that match the class’s
  `initialize()` formals.** A credential silently never receives context
  it does not declare as an argument — the symptom is a default quietly
  winning, with no error.
- **`build_credential_context()` drops `NULL`s and deliberately excludes
  `interactive`.** Interactivity is chain-runner policy in
  `try_build_credential()`, not a constructor argument; passing it down
  would override a credential’s own defaults, such as
  `AzureCLICredential`’s `cli_auto_login`.
- **The order of
  [`default_credential_chain()`](https://pedrobtz.github.io/azr/dev/reference/default_credential_chain.md)
  is a semantic decision, not a preference.** `workload_identity` and
  `managed_identity` come before `azure_cli`, so on a host configured
  for a service identity
  [`get_token()`](https://pedrobtz.github.io/azr/dev/reference/get_token.md)
  returns the *workload’s* token even with a person at the console. That
  is why
  [`get_user_token()`](https://pedrobtz.github.io/azr/dev/reference/get_user_token.md)
  exists. Reordering silently changes who a token belongs to.
- **A Suggests package must degrade, never prompt.** Guard with
  [`rlang::is_installed()`](https://rlang.r-lib.org/reference/is_installed.html)
  and skip the optional step.
  [`rlang::check_installed()`](https://rlang.r-lib.org/reference/is_installed.html)
  interrupts a login flow to ask about an install, which is the wrong
  thing to do mid-authentication.
- **Nothing that prints configuration may print a secret.**
  `Credential$print()` redacts through `list_redact()` and
  [`az_config()`](https://pedrobtz.github.io/azr/dev/reference/az_config.md)
  reports `AZURE_CLIENT_SECRET` as redacted. Any new surface that
  reports config must do the same.
- **`.onAttach()` renders `format_az_config()`.** An error in that path
  makes the package fail to attach, so it must tolerate any environment.
- **S7 methods need
  [`S7::methods_register()`](https://rconsortium.github.io/S7/reference/methods_register.html)
  in `.onLoad()`.** New S7 generics or methods only dispatch because of
  that call.
- **A new top-level file needs an `.Rbuildignore` entry** or
  `R CMD check` raises a NOTE for a non-standard file at the package
  root.

## Testing conventions

- testthat edition 3. Tests for `R/{name}.R` live in
  `tests/testthat/test-{name}.R`.
- **Build inputs inside the `test_that()` block.** File-scope helpers
  shared between blocks are what breaks `shuffle = TRUE`; shared
  fixtures belong in `tests/testthat/helper-*.R`, which is sourced
  before any block runs.
- **No live Azure calls.** HTTP-layer tests replay vcr cassettes from
  `tests/testthat/_vcr/`, recorded against the public Swagger Petstore
  rather than Azure, so they exercise `api_client` without credentials.
- **Assert on condition classes, not message text** — the package raises
  classed conditions such as `azr_credential_chain_failed`,
  `azr_cli_not_logged_in`, `azr_cli_timeout_error` and
  `azr_requires_interactive_session`. Wording belongs in snapshot tests.
- **Isolate the environment.** These tests read the same `AZURE_*`
  variables as production code; set them through
  [`withr::local_envvar()`](https://withr.r-lib.org/reference/with_envvar.html).
  A test that reads a variable it did not set will pass or fail
  depending on whose laptop it runs on.
- Gate on capability, not platform:
  `skip_if_not(rlang::is_interactive())`,
  `skip_if_not_installed("httpuv")`,
  `skip_if_not(nzchar(Sys.which("az")))`.
- `tests/testthat/helper-resource.R` defines the `api_store_resource`
  subclass that the `api_resource` and `api_service` tests build on.
- Keep the suite near its current ~11 seconds.

## Definition of done

`devtools::document()` and `devtools::check(error_on = "warning")`
clean: 0 errors, 0 warnings, 0 notes. `devtools::test(shuffle = TRUE)`
green, with the one known exception recorded under Current state.
`air format .` run. A user-facing change also needs a test, roxygen
documentation and a `NEWS.md` bullet.

NEWS bullets are one line, present tense, positively framed, with the
function name in backticks near the start, and the issue number before
the final period: `` * `fn()` now accepts ... (@user, #N). ``. **Never
invent an issue number** — take it from the prompt, the branch name or
`gh issue list`, and use `#noissue` if there is none.

## Editing rules

- roxygen comments are the source. Never edit `man/` or `NAMESPACE` by
  hand; they come from `devtools::document()`.
- Every user-facing function is exported with roxygen docs; internal
  ones get no roxygen topic.
- A new documentation topic goes into `_pkgdown.yml`, verified with
  [`pkgdown::check_pkgdown()`](https://pkgdown.r-lib.org/reference/check_pkgdown.html).
- Errors use
  [`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)
  with a condition class, following tidyverse style.
- Newspaper style: main logic at the top, helpers below. Avoid defining
  functions inside functions.
- Comments explain why, not what. Sentence case for headings.

## Continuous integration

Workflows live in `.github/workflows/` and are derived from
`r-lib/actions` examples rather than called from the shared
`pedrobtz/r-actions` repository, so they are maintained here:
`R-CMD-check.yaml` (a 10-job matrix across macOS, Windows and Linux, R
release back to oldrel-4), plus `lint.yaml`, `test-coverage.yaml`,
`pkgdown.yaml`, `rhub.yaml` and `pr-commands.yaml`.

## Commits and pull requests

Short, imperative, sentence-case commit subjects. Keep each commit
focused and do not sweep in unrelated files. A pull request explains the
user-visible outcome and the rationale, links related issues, and lists
the checks that were run and the tests that were skipped.

Never commit or push to `main`. Work on a branch, open a pull request,
and leave it for review. Do not merge a pull request unless you are told
to.

When you find a defect, in this package or upstream, record it in
`.dev/TODO.md` with a <file:line> reference or open an issue, rather
than only working around it.
