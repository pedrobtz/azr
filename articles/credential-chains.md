# Building credential chains

``` r

library(azr)
```

A *credential chain* is an ordered list of authentication methods. When
you ask for a token, `azr` walks the chain from top to bottom and
returns the first credential that successfully authenticates. This lets
the same code run unchanged on a laptop (interactive login), in CI (a
client secret), and on a managed Azure host (managed identity).

This vignette shows how to build and use chains.

## The default chain

Most of the time you don’t build a chain at all — the high-level
functions use
[`default_credential_chain()`](https://pedrobtz.github.io/azr/reference/default_credential_chain.md)
automatically:

``` r

default_credential_chain()
```

Each line is one *entry*: a name on the left and the credential it will
try on the right. The chain is attempted top to bottom, so
non-interactive methods (client secret, workload identity, managed
identity, Azure CLI) come before the interactive browser/device-code
flows.

You get a token without ever mentioning the chain:

``` r

token <- get_token(scope = "https://graph.microsoft.com/.default")
```

[`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md),
[`get_request_authorizer()`](https://pedrobtz.github.io/azr/reference/get_request_authorizer.md),
[`get_token_provider()`](https://pedrobtz.github.io/azr/reference/get_token_provider.md),
[`get_credential_auth()`](https://pedrobtz.github.io/azr/reference/get_credential_auth.md),
and
[`get_credential_provider()`](https://pedrobtz.github.io/azr/reference/get_credential_provider.md)
all take a `chain =` argument that defaults to
[`default_credential_chain()`](https://pedrobtz.github.io/azr/reference/default_credential_chain.md).

## Building a custom chain

Use
[`credential_chain()`](https://pedrobtz.github.io/azr/reference/credential_chain.md)
to build your own. Pass **named** entries; each entry is either:

- a credential **class** (e.g. `ClientSecretCredential`),
- an already-constructed `Credential` **instance**.

``` r

chain <- credential_chain(
  client_secret = ClientSecretCredential,
  azure_cli     = AzureCLICredential
)

chain
```

The names (`client_secret`, `azure_cli`) are labels – they show up when
the chain prints and in verbose/error output, so pick something
recognisable.

Constructing a chain does **no** authentication. Credential
configuration is validated when a chain entry is tried, just before the
first token request:

``` r

token <- get_token(
  scope = "https://graph.microsoft.com/.default",
  chain = chain
)
```

## How context flows into each entry

When you call `get_token(scope = ..., tenant_id = ..., ...)`, those
values form a *context* that is handed to each class entry as it is
tried. Each credential only receives the context arguments its own
constructor accepts – a `ManagedIdentityCredential` takes `scope` and
`client_id`, so a `tenant_id` in the context is simply ignored for that
entry.

This is why a single `get_token(scope = ...)` call works across every
method in the chain: the scope is forwarded to whichever credential ends
up succeeding.

Constructed instances are different: they are used **as-is**. Use an
instance when a chain entry has its own configuration:

``` r

prod_secret <- ClientSecretCredential$new(
  tenant_id = "11111111-1111-1111-1111-111111111111",
  client_id = "app-registration-id",
  client_secret = "super-secret-value"
)

chain <- credential_chain(
  prod_secret = prod_secret,
  azure_cli = AzureCLICredential
)

chain
```

Credential objects validate their configuration at construction, so an
incomplete object fails fast rather than at token time:

``` r

ClientSecretCredential$new(client_secret = NULL)
```

Note that sensitive values are redacted when a credential prints:

``` r

ClientSecretCredential$new(client_secret = "super-secret-value")
```

## Using a pre-built instance

``` r

my_cli <- AzureCLICredential$new(auto_login = FALSE)

chain <- credential_chain(
  configured_cli = my_cli,
  fallback       = DeviceCodeCredential
)
```

## Reusing a chain with `DefaultCredential`

`DefaultCredential` wraps a chain in an object with a lazily-resolved
provider. The chain is resolved once on first use and the winning
credential is reused for later calls:

``` r

cred <- DefaultCredential$new(
  scope = "https://graph.microsoft.com/.default",
  chain = chain
)

# First call resolves the chain; later calls reuse the same provider.
token <- cred$get_token()
resp  <- httr2::req_perform(cred$req_auth(httr2::request(url)))
```

## Seeing which credential wins

Set the `chain_verbose` option (or the `AZR_CHAIN_VERBOSE` environment
variable) to watch the chain being walked — each entry tried, which
fail, and which one finally returns a token:

``` r

options(azr.chain_verbose = TRUE)
get_token(scope = "https://graph.microsoft.com/.default", chain = chain)
```

If every entry fails,
[`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)
aborts with a combined report listing each named entry and the error it
raised, so you can see why the whole chain came up empty.
