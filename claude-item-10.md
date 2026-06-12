# Credential chain argument passing — revised design

Supersedes [item-10.md](item-10.md); addendum to [review.md](review.md) item 11
("The credential chain passes arguments by environment scraping — fragile and
surprising").

## What changed relative to item-10.md

The original proposal is the right shape, but it bundles a small bug fix with a
larger API redesign and sequences them in the wrong order. This revision:

1. **Splits the work into two phases.** Phase 1 fixes every concrete bug in
   review item 11 with a ~15-line diff and no new exported API. Phase 2 adds
   `credential_spec()` for per-entry overrides.
2. **Corrects an ordering dependency.** Item-10's implementation outline makes
   `credential_chain()` eager (step 2) before making constructors
   side-effect-free (step 6). In that order, merely *defining* a chain
   containing `AzureCLICredential$new(...)` could launch `az login`.
   Side-effect-free constructors must land first.
3. **Drops the runner-side interactivity move as a separate step.** The runner
   already enforces interactivity policy at
   [default-credential.R:592](R/default-credential.R#L592); the constructor
   check at [credential.R:30-34](R/credential.R#L30-L34) is the redundant one.
4. **Pins down three edge cases** the original sketch glossed over: explicit
   `NULL` in the merge, `...` in `initialize()` formals, and eager capture of
   secrets inside specs.

## Decision

**Phase 1 (bug fix, non-breaking):** replace execution-frame scraping with an
explicit context list, and remove `interactive` from the values that reach
constructors. Chain entries stay lazily evaluated quosures.

**Phase 2 (API, after constructors are side-effect-free):** make
`credential_chain()` eager data, add `credential_spec()` for entries that need
custom arguments, and rename the three overloaded interaction settings.

The precedence rule, both phases:

**entry arguments > provider context > credential constructor defaults**

Context values are passed only when the credential's `initialize()` accepts the
corresponding argument by name.

---

## Phase 1 — explicit context, no new API

### Problem being fixed

`new_instance()` ([default-credential.R:680-691](R/default-credential.R#L680-L691))
harvests variables from `get_credential_provider()`'s frame by name-matching
against `initialize()` formals. Consequences:

- `interactive`, `oauth_host`, and `oauth_endpoint` look unused in the body but
  act via name-matching; renaming a local variable silently changes behavior.
- `interactive = rlang::is_interactive()` leaks into
  `AzureCLICredential$new()`, overriding its documented `cli_auto_login`
  default and triggering unsolicited `az login` during chain traversal.

### Fix

`get_credential_provider()` builds a fixed, documented context and threads it
explicitly. `interactive` is deliberately **not** in the context — it is
runner policy, which is what its documentation already claims:

```r
get_credential_provider <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  oauth_host = NULL,
  oauth_endpoint = NULL,
  chain = NULL,
  interactive = rlang::is_interactive(),
  verbose = opts$get("chain_verbose")
) {
  context <- list(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    oauth_host = oauth_host,
    oauth_endpoint = oauth_endpoint
  )

  # At provider level, NULL means "not configured": drop it so the
  # constructor's own default applies.
  context <- Filter(Negate(is.null), context)

  # ... existing loop, but:
  built <- try_build_credential(
    chain[[i]],
    crd_name = crd_name,
    context = context,
    interactive = interactive,
    verbose = verbose
  )
  # ...
}
```

`new_instance()` keeps the useful part of the current implementation — matching
names against `initialize()` formals — but reads from the explicit context
instead of a frame:

```r
new_instance <- function(cls, context) {
  accepted <- setdiff(r6_get_initialize_arguments(cls), "...")
  args <- context[intersect(names(context), accepted)]
  rlang::exec(cls$new, !!!args)
}
```

Two deliberate choices here:

- `"..."` is removed from the accepted names. A class whose `initialize()` has
  `...` receives only context values matching its *named* formals; dots never
  cause the full context to be splatted in. This keeps typo detection intact.
- `rlang::exec()` replaces the `eval(rlang::call2(...))` construction — same
  effect, one less layer.

`try_build_credential()` enforces the interactivity policy with the parameter
it is given, instead of re-reading the session state
([default-credential.R:592](R/default-credential.R#L592) today):

```r
if (obj$is_interactive() && !interactive) {
  return(fail("Credential requires an interactive session"))
}
```

With `interactive` absent from the context, `AzureCLICredential` falls back to
its own constructor default, which restores the documented `cli_auto_login`
behavior in chain usage. Pre-built instance entries and constructor-call
quosure entries (e.g. `azure_cli = AzureCLICredential$new(tenant_id = "...")`)
behave exactly as today.

### What Phase 1 does *not* give you

A way to say "inherit the provider's `tenant_id` but override only `scope` for
this entry." Today that requires spelling out a full constructor call as the
chain entry. That convenience gap is Phase 2's job; nothing in Phase 1 blocks
it.

---

## Phase 2 — `credential_spec()` and eager chains

### Prerequisite: side-effect-free constructors

Before `credential_chain()` evaluates entries eagerly, constructing a
credential must be observably free of authentication side effects:

- Remove the session-interactivity abort from `Credential$initialize()`
  ([credential.R:30-34](R/credential.R#L30-L34)). The chain runner already
  enforces this policy; for direct (non-chain) construction, move the check to
  `get_token()`, which is where the prompt would actually occur.
- `AzureCLICredential$initialize()` must not check login state or launch
  `az login`. Authentication belongs in `get_token()`.

This ordering is load-bearing. Eager evaluation of
`credential_chain(cli = AzureCLICredential$new(...))` runs the constructor at
chain-definition time; if constructors still authenticate, defining a chain
performs network and subprocess work.

### Entry types

A chain entry is one of:

| Entry | Receives context? | Constructed |
|---|---|---|
| bare class generator | yes (accepted names only) | lazily, at traversal |
| `credential_spec(Class, ...)` | yes, under entry args | lazily, at traversal |
| pre-built `Credential` instance | no — authoritative | eagerly, at definition |

A bare class is equivalent to `credential_spec(Class)`. The factory-function
escape hatch from item-10 stays out until a concrete use case cannot be
expressed by these three forms.

### `credential_spec()`

```r
credential_spec <- function(class, ...) {
  args <- rlang::list2(...)

  if (!R6::is.R6Class(class)) {
    cli::cli_abort(
      "{.arg class} must be an R6 credential class generator,
       not {.obj_type_friendly {class}}."
    )
  }

  if (length(args) > 0L && !rlang::is_named(args)) {
    cli::cli_abort("All arguments to {.fn credential_spec} must be named.")
  }

  accepted <- setdiff(r6_get_initialize_arguments(class), "...")
  unknown <- setdiff(names(args), accepted)
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "Unknown argument{?s} {.arg {unknown}} for {.cls {class$classname}}.",
      "i" = "Accepted: {.arg {accepted}}."
    ))
  }

  structure(
    list(class = class, args = args),
    class = "azr_credential_spec"
  )
}
```

Validation happens when the spec is created — unknown and unnamed arguments
fail at chain definition, not at traversal.

`rlang::list2()` preserves an explicit `NULL` element, so
`credential_spec(SomeCredential, scope = NULL)` is distinguishable from an
omitted `scope`: the former passes `NULL` to the constructor; the latter lets
the context value or the formal default apply.

**Secrets caveat.** Eager evaluation means
`credential_spec(ClientSecretCredential, client_secret = Sys.getenv("X"))`
captures the secret into the spec object for its whole lifetime. Redaction in
`print()` *and* `format()` is therefore mandatory, not cosmetic:

```r
spec_sensitive_pattern <- "secret|token|password|key"

format.azr_credential_spec <- function(x, ...) {
  shown <- x$args
  redact <- grepl(spec_sensitive_pattern, names(shown), ignore.case = TRUE)
  shown[redact] <- "<hidden>"
  # ... render class name + shown args
}

print.azr_credential_spec <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}
```

### Eager `credential_chain()`

```r
credential_chain <- function(...) {
  entries <- rlang::list2(...)

  if (length(entries) == 0L) {
    cli::cli_abort(c(
      "Credential chain cannot be empty.",
      "i" = "Provide at least one credential class, spec, or instance.",
      "i" = "Use {.fn default_credential_chain} for a pre-configured chain."
    ))
  }

  entries <- lapply(entries, function(entry) {
    if (R6::is.R6Class(entry)) {
      return(credential_spec(entry))
    }
    if (inherits(entry, "azr_credential_spec")) {
      return(entry)
    }
    if (R6::is.R6(entry) && inherits(entry, "Credential")) {
      return(entry)
    }
    cli::cli_abort(
      "Chain entries must be a credential class, {.fn credential_spec},
       or a {.cls Credential} instance."
    )
  })

  structure(entries, class = "credential_chain")
}
```

The chain is now ordinary inspectable data: every entry is validated and
normalized at definition, `print.credential_chain` can list entries with
redacted specs, and traversal no longer needs `rlang::eval_tidy()`.

**Behavior change (NEWS entry required):** entries are no longer quosures, so
an instance-construction expression in a chain definition runs at definition
time rather than first traversal. With side-effect-free constructors this is
cheap and invisible, but it is observable to anyone relying on the old
laziness.

### Building an entry

```r
build_credential <- function(entry, context) {
  if (R6::is.R6(entry) && inherits(entry, "Credential")) {
    return(entry) # pre-built instance: no context merge
  }

  accepted <- setdiff(r6_get_initialize_arguments(entry$class), "...")
  args <- context[intersect(names(context), accepted)]

  # List-RHS `[<-` preserves explicit NULL entry args. modifyList() would
  # *delete* them, silently re-enabling the constructor default — do not
  # "simplify" to it.
  args[names(entry$args)] <- entry$args

  rlang::exec(entry$class$new, !!!args)
}
```

The merge is shallow by design: each constructor argument is one value, and an
entry-level list replaces the context value rather than being recursively
combined.

### Interaction policy renames

Unchanged from item-10, restated for completeness. `interactive` currently
names three different concepts; give each its own name:

- `allow_interactive` — chain-runner policy (may a prompting credential run);
- `auto_login` — may `AzureCLICredential` launch `az login` (replaces
  `cli_auto_login`);
- `allow_prompt` — may an interactive OAuth credential prompt instead of
  reading its cache.

The cached-token chain then reads as configuration, not behavior buried in
constructors:

```r
cached_token_credential_chain <- function() {
  credential_chain(
    auth_code = credential_spec(AuthCodeCredential, allow_prompt = FALSE),
    device_code = credential_spec(DeviceCodeCredential, allow_prompt = FALSE),
    azure_cli = credential_spec(AzureCLICredential, auto_login = FALSE)
  )
}
```

`get_credential_provider(interactive = )` becomes `allow_interactive =`, with
`interactive` kept as a deprecated alias for one release.

### Usage after both phases

```r
chain <- credential_chain(
  # Bare class: inherits applicable context values.
  managed_identity = ManagedIdentityCredential,

  # Spec: context values, with targeted overrides.
  client_secret = credential_spec(
    ClientSecretCredential,
    scope = "api://my-app/.default",
    offline = FALSE
  ),

  # Pre-built instance: authoritative, no merge.
  custom = AzureCLICredential$new(tenant_id = "...")
)

token <- get_token(
  tenant_id = "common-tenant",   # context for the first two entries
  chain = chain
)
```

---

## Scope contract

Per-entry scope overrides remain supported because app-only and delegated
credentials may require different scopes for the same API. A chain-level
`scope` is only the context default for entries that do not override it.

This design does not redefine `get_token(scope = ...)`. Dynamic scope support
and pinned-scope behavior affect token caching and incremental consent and
deserve a separate decision.

## What this fixes

1. Renaming a runner-local variable cannot change constructor behavior
   (Phase 1).
2. `allow_interactive` policy can no longer leak into `AzureCLICredential` and
   trigger unsolicited `az login`; `cli_auto_login`/`auto_login` works in
   chains again (Phase 1).
3. Constructor inputs have a documented source and precedence (Phase 1).
4. Per-entry overrides with context inheritance (Phase 2).
5. Entry-level explicit `NULL` reaches the constructor instead of being
   filtered away (Phase 2).
6. Chains are inspectable, printable data with secret redaction (Phase 2).
7. Invalid entry arguments fail at definition time (Phase 2).

## Implementation order

1. **Phase 1** — explicit context in `get_credential_provider()`; rewrite
   `new_instance(cls, context)`; thread `interactive` to
   `try_build_credential()` as policy only. No exported API change.
2. Make constructors side-effect-free: move the interactivity abort and Azure
   CLI login effects into `get_token()`.
3. **Phase 2** — add `credential_spec()` + redacting `format()`/`print()`;
   make `credential_chain()` eager; replace quosure evaluation in the runner
   with `build_credential(entry, context)`.
4. Rename interaction settings (`allow_interactive`, `auto_login`,
   `allow_prompt`) with deprecated aliases.
5. NEWS: eager-chain behavior change; deprecations.

## Test obligations

Phase 1:

- A context value reaches a class whose `initialize()` accepts it; it is not
  passed to a class that does not.
- `interactive` never reaches a constructor; `AzureCLICredential` in the
  default chain is constructed with its own `cli_auto_login` default.
- Renaming runner locals is structurally impossible to test, but the context
  list is asserted to contain exactly the eight documented names.
- A class whose `initialize()` contains `...` receives only named-formal
  matches.

Phase 2:

- An entry argument overrides a context value; a context value overrides
  nothing explicitly set; an omitted argument falls through to the formal
  default.
- An entry-level explicit `NULL` reaches the constructor as `NULL`
  (regression guard against a `modifyList()` rewrite).
- A pre-built instance receives no context merge.
- Unknown or unnamed spec arguments fail when the spec is created.
- Defining a chain performs no authentication: no subprocess, no network, no
  prompt (guards the side-effect-free prerequisite).
- `allow_interactive = FALSE` prevents construction-time prompting and token
  acquisition by interactive credentials.
- Printing a chain or spec never reveals client secrets, refresh tokens, or
  other sensitive constructor arguments — covered for `print()` and
  `format()`.
