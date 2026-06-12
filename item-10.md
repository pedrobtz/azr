# Credential chain argument passing - design proposal

Addendum to [review.md](review.md) item 11 ("The credential chain passes arguments
by environment scraping - fragile and surprising").

## Decision

Represent each configurable chain entry as an explicit, immutable credential
specification.

Configuration values are evaluated when the chain is defined, making the chain
ordinary inspectable data. Credential objects are still constructed lazily, when
the runner attempts that entry.

The precedence rule is:

**entry arguments > provider defaults > credential constructor defaults**

Provider defaults are passed only when the credential's `initialize()` method
accepts the corresponding argument.

## Goals

- Preserve per-credential configuration, including different scopes in one
  chain.
- Preserve bare credential classes and pre-built credential instances.
- Keep credential construction lazy.
- Make argument sources and precedence explicit.
- Distinguish an entry-level explicit `NULL` from an unspecified argument.
- Keep chain policy separate from credential constructor configuration.

This proposal does not redesign call-time scope handling or credential token
caches. Those can be considered independently.

## Proposed API

Keep `credential_chain()` as the user-facing chain constructor and add a small
`credential_spec()` helper for entries requiring custom arguments:

```r
chain <- credential_chain(
  # A bare class inherits applicable provider defaults.
  managed_identity = ManagedIdentityCredential,

  # This entry overrides the provider's scope and offline settings.
  client_secret = credential_spec(
    ClientSecretCredential,
    scope = "api://my-app/.default",
    offline = FALSE
  ),

  # The interactive entry can use a delegated scope.
  device_code = credential_spec(
    DeviceCodeCredential,
    scope = "https://graph.microsoft.com/User.Read"
  ),

  # A pre-built instance remains authoritative and receives no merged arguments.
  custom = AzureCLICredential$new(tenant_id = "...")
)
```

A bare class is equivalent to `credential_spec(Class)`. Keeping the shorthand
preserves the current concise default-chain definitions.

## Specification representation

The specification stores evaluated values rather than quosures:

```r
credential_spec <- function(class, ...) {
  structure(
    list(
      class = class,
      args = rlang::list2(...)
    ),
    class = "azr_credential_spec"
  )
}
```

Eagerly evaluating configuration is intentional. It makes specifications easy to
validate, print, compare, and test. Lazy evaluation is retained where it matters:
the credential itself is not constructed until the chain reaches that entry.

The specification constructor should validate that:

- `class` is an R6 credential class;
- all arguments are named;
- argument names are accepted by the class's `initialize()` method; and
- sensitive argument values are redacted by any print method.

## Provider defaults

`get_credential_provider()` creates a fixed, documented context rather than
exposing its execution frame:

```r
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

# At provider level, NULL means "not configured".
context <- Filter(Negate(is.null), context)
```

Values such as `use_cache = "disk"` and `offline = TRUE` are provider defaults,
not necessarily arguments explicitly supplied by the caller. This distinction is
important because wrapper functions cannot reliably preserve whether their own
defaulted arguments were originally omitted.

An explicit `NULL` override remains available at entry level:

```r
credential_spec(SomeCredential, scope = NULL)
```

This means "pass `NULL` to this constructor." It does not invoke R's formal
argument default. Omitting `scope` from both the entry and provider context is
what allows the constructor's formal default to apply.

## Building an entry

The runner normalizes a bare class to an empty specification, passes through an
existing credential instance, and otherwise merges accepted provider defaults
with entry arguments:

```r
build_credential <- function(entry, context) {
  if (is_credential(entry)) {
    return(entry)
  }

  if (R6::is.R6Class(entry)) {
    entry <- credential_spec(entry)
  }

  accepted <- r6_get_initialize_arguments(entry$class)
  args <- context[intersect(names(context), accepted)]
  args[names(entry$args)] <- entry$args

  rlang::exec(entry$class$new, !!!args)
}
```

The merge is deliberately shallow. Each constructor argument is one value; a
list-valued entry argument should replace the provider value rather than be
recursively combined with it.

This preserves the useful part of the current implementation - matching argument
names against `initialize()` - while replacing the execution frame with explicit
inputs.

## Interaction policy

The word `interactive` currently describes three different concepts:

- whether the chain runner permits a prompting credential;
- whether `AzureCLICredential` may launch `az login`; and
- whether an interactive OAuth credential may prompt instead of reading cache.

Use distinct names:

- `allow_interactive` for chain-runner policy;
- `auto_login` for `AzureCLICredential`; and
- `allow_prompt` for interactive OAuth credentials.

For example, the cached-token chain becomes explicit:

```r
cached_token_credential_chain <- function() {
  credential_chain(
    auth_code = credential_spec(
      AuthCodeCredential,
      allow_prompt = FALSE
    ),
    device_code = credential_spec(
      DeviceCodeCredential,
      allow_prompt = FALSE
    ),
    azure_cli = credential_spec(
      AzureCLICredential,
      auto_login = FALSE
    )
  )
}
```

Credential constructors should be side-effect-free. In particular,
`AzureCLICredential$initialize()` should not check login state or launch
`az login`. Authentication and prompting belong in `get_token()`.

Once construction is side-effect-free, the runner can construct an entry, inspect
`is_interactive()`, and apply `allow_interactive` before attempting token
acquisition. The session-interactivity check in `Credential$initialize()` should
therefore move to the runner as well.

## What this fixes

1. Renaming a runner-local variable cannot change constructor behavior.
2. Constructor inputs have a documented source and precedence.
3. The chain's `allow_interactive` policy cannot accidentally enable Azure CLI
   auto-login.
4. Entry-level `NULL` is preserved rather than removed by frame filtering.
5. Cached-token behavior is visible in the chain definition.
6. Chain entries can be inspected without evaluating delayed expressions.
7. Pre-built instances remain available for fully custom behavior.

## Alternative: factory functions

A factory entry could offer unrestricted construction:

```r
client_secret = function(context) {
  ClientSecretCredential$new(
    scope = "api://my-app/.default",
    tenant_id = context$tenant_id
  )
}
```

Factories are more flexible, but they are harder to validate, inspect, document,
print safely, and reason about. They should not be the primary API. A factory
escape hatch can be added later if a concrete use case cannot be represented by
a class, a specification, or a pre-built instance.

## Scope contract

Per-entry scope overrides remain supported because app-only and delegated
credentials may require different scopes for the same API. A chain-level `scope`
is only the provider default for entries that do not override it.

This change should not also redefine `get_token(scope = ...)`. Dynamic scope
support and the behavior of pinned scopes deserve a separate decision because
they affect token caching and incremental consent.

As today, entries in a chain should ultimately produce tokens accepted by the
same target API. Mixing unrelated resource audiences can authenticate
successfully but fail when the token is used.

## Implementation outline

1. Add and document `credential_spec()`.
2. Make `credential_chain()` eagerly collect and validate entries.
3. Replace `new_instance()` frame access with explicit context merging.
4. Normalize bare classes to empty specifications in the runner.
5. Rename the three overloaded interaction settings.
6. Move constructor authentication effects into `get_token()`.
7. Move session interaction policy out of `Credential$initialize()`.
8. Redact sensitive values when printing chain specifications.

## Test obligations

- An entry argument overrides a provider default.
- A bare class receives applicable provider defaults.
- A provider value is not passed to a class that does not accept it.
- An entry-level explicit `NULL` reaches the constructor as `NULL`.
- Omitting an argument allows the constructor default to apply.
- A pre-built instance receives no context merge.
- Unknown or unnamed entry arguments fail when the specification is created.
- Chain definitions do not construct credentials.
- `allow_interactive = FALSE` prevents prompting and token acquisition by
  interactive credentials.
- Printing a chain never reveals client secrets, refresh tokens, or other
  sensitive constructor arguments.
