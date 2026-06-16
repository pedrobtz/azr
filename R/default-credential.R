#' Default credential authentication
#'
#' @description
#' An R6 class that provides lazy initialization of credential providers.
#' The credential provider is created on first access using the default
#' credential chain.
#'
#' @details
#' This class wraps the credential discovery process in an R6 object with
#' a lazily evaluated `provider` field. The provider is only created when
#' first accessed, using the same logic as [get_token_provider()].
#'
#' @export
#' @examples
#' # Create a DefaultCredential object
#' cred <- DefaultCredential$new(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "my-tenant-id"
#' )
#'
#' \dontrun{
#' # Get a token (triggers lazy initialization)
#' token <- cred$get_token()
#'
#' # Authenticate a request
#' req <- httr2::request("https://management.azure.com/subscriptions")
#' resp <- httr2::req_perform(cred$req_auth(req))
#'
#' # Or access the provider directly
#' provider <- cred$provider
#' }
#'
#' @field .scope Character string specifying the authentication scope.
#' @field .tenant_id Character string specifying the tenant ID.
#' @field .client_id Character string specifying the client ID.
#' @field .client_secret Character string specifying the client secret.
#' @field .use_cache Character string indicating the caching strategy.
#' @field .offline Logical indicating whether to request offline access.
#' @field .chain A credential chain object for authentication.
#' @field .verbose Logical indicating whether to print the resolved provider class.
DefaultCredential <- R6::R6Class(
  classname = "DefaultCredential",
  public = list(
    .scope = NULL,
    .tenant_id = NULL,
    .client_id = NULL,
    .client_secret = NULL,
    .use_cache = NULL,
    .offline = NULL,
    .chain = NULL,
    .verbose = NULL,

    #' @description
    #' Create a new DefaultCredential object
    #'
    #' @param scope Optional character string specifying the authentication scope.
    #' @param tenant_id Optional character string specifying the tenant ID for
    #'   authentication.
    #' @param client_id Optional character string specifying the client ID for
    #'   authentication.
    #' @param client_secret Optional character string specifying the client secret
    #'   for authentication.
    #' @param use_cache Character string indicating the caching strategy. Defaults
    #'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
    #'   for in-memory caching.
    #' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to request a 'refresh_token'.
    #'   Defaults to `TRUE`.
    #' @param chain A list of credential objects, where each element must inherit
    #'   from the `Credential` base class. Credentials are attempted in the order
    #'   provided until `get_token` succeeds.
    #' @param verbose Logical. If `TRUE`, prints the resolved credential provider
    #'   on first access. Defaults to the `chain_verbose` option
    #'   (`options(azr.chain_verbose = ...)` or `AZR_CHAIN_VERBOSE`); see
    #'   [azr_options()].
    #'
    #' @return A new `DefaultCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      client_secret = NULL,
      use_cache = c("disk", "memory"),
      offline = TRUE,
      chain = default_credential_chain(),
      verbose = opts$get("chain_verbose")
    ) {
      self$.scope <- scope
      self$.tenant_id <- tenant_id
      self$.client_id <- client_id
      self$.client_secret <- client_secret
      self$.use_cache <- rlang::arg_match(use_cache)
      self$.offline <- offline
      self$.chain <- chain
      self$.verbose <- verbose
    },

    #' @description
    #' Get an access token using the credential chain
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function() {
      self$provider$get_token()
    },

    #' @description
    #' Add authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with authentication configured
    req_auth = function(req) {
      self$provider$req_auth(req)
    }
  ),
  active = list(
    #' @field provider Lazily initialized credential provider
    provider = function() {
      if (is.null(private$.provider_cache)) {
        private$.provider_cache <- get_credential_provider(
          scope = self$.scope,
          tenant_id = self$.tenant_id,
          client_id = self$.client_id,
          client_secret = self$.client_secret,
          use_cache = self$.use_cache,
          offline = self$.offline,
          chain = self$.chain
        )
        if (isTRUE(self$.verbose)) {
          cli::cli_inform("Using provider:")
          print(private$.provider_cache)
        }
      }
      private$.provider_cache
    }
  ),
  private = list(
    .provider_cache = NULL
  )
)


#' Get Default Token Provider Function
#'
#' Creates a token provider function that retrieves authentication credentials
#' and returns a callable token getter. This function handles the credential
#' discovery process and returns the token acquisition method from the
#' discovered credential object.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to request a 'refresh_token'.
#'   Defaults to `TRUE`.
#' @param chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#'
#' @return A function that retrieves and returns an authentication token when
#'   called.
#'
#' @seealso [get_request_authorizer()], [get_token()]
#'
#' @examples
#' # In non-interactive sessions, this function will return an error if the
#' # environment is not set up with valid credentials. In an interactive session
#' # the user will be prompted to attempt one of the interactive authentication flows.
#' \dontrun{
#' token_provider <- get_token_provider(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "my-tenant-id",
#'   client_id = "my-client-id",
#'   client_secret = "my-secret"
#' )
#' token <- token_provider()
#' }
#'
#' @export
get_token_provider <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
) {
  provider <- get_credential_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    chain = chain
  )

  function() {
    provider$get_token()
  }
}

#' Get Default Request Authorizer Function
#'
#' Creates a request authorizer function that retrieves authentication credentials
#' and returns a callable request authorization method. This function handles the
#' credential discovery process and returns the request authentication method
#' from the discovered credential object.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to request a 'refresh_token'.
#'   Defaults to `TRUE`.
#' @param chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#'
#' @return A function that authorizes HTTP requests with appropriate credentials
#'   when called.
#'
#'
#' @seealso [get_token_provider()], [get_token()]
#'
#' @examples
#' # In non-interactive sessions, this function will return an error if the
#' # environment is not setup with valid credentials. And in an interactive session
#' # the user will be prompted to attempt one of the interactive authentication flows.
#' \dontrun{
#' req_auth <- get_request_authorizer(
#'   scope = "https://graph.microsoft.com/.default"
#' )
#' req <- req_auth(httr2::request("https://graph.microsoft.com/v1.0/me"))
#' }
#'
#' @export
get_request_authorizer <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
) {
  provider <- get_credential_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    chain = chain
  )

  function(req) {
    provider$req_auth(req)
  }
}

#' Get Authentication Token
#'
#' Retrieves an authentication token using the default token provider. This is
#' a convenience function that combines credential discovery and token
#' acquisition in a single step.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to request a 'refresh_token'.
#'   Defaults to `TRUE`.
#' @param chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#'
#' @return An [httr2::oauth_token()] object.
#'
#' @seealso [get_token_provider()], [get_request_authorizer()]
#'
#' @examples
#' # In non-interactive sessions, this function will return an error if the
#' # environment is not setup with valid credentials. And in an interactive session
#' # the user will be prompted to attempt one of the interactive authentication flows.
#' \dontrun{
#' token <- get_token(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "my-tenant-id",
#'   client_id = "my-client-id",
#'   client_secret = "my-secret"
#' )
#' }
#'
#' @export
get_token <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
) {
  provider <- get_credential_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    chain = chain
  )

  provider$get_token()
}


#' Get Credential Authentication Function
#'
#' @description
#' Creates a function that retrieves authentication tokens and formats them as
#' HTTP Authorization headers. This function handles credential discovery and
#' returns a callable method that generates Bearer token headers when invoked.
#'
#' @inheritParams get_token
#'
#' @return A function that, when called, returns a named list with an
#'   `Authorization` element containing the Bearer token, suitable for use
#'   with [httr2::req_headers()].
#'
#' @seealso [get_token()], [get_request_authorizer()], [get_token_provider()]
#'
#' @examples
#' \dontrun{
#' # Create an authentication function
#' auth_fn <- get_credential_auth(
#'   scope = "https://graph.microsoft.com/.default"
#' )
#'
#' # Call it to get headers
#' auth_headers <- auth_fn()
#'
#' # Use with httr2
#' req <- httr2::request("https://graph.microsoft.com/v1.0/me") |>
#'   httr2::req_headers(!!!auth_headers)
#' }
#'
#' @export
get_credential_auth <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
) {
  get_token <- get_token_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    chain = chain
  )

  function() {
    token <- get_token()
    list(Authorization = paste0("Bearer ", token$access_token))
  }
}


#' Get Credential Provider
#'
#' @description
#' Discovers and returns an authenticated credential object from a chain of
#' credential providers. This function attempts each credential in the chain
#' until one successfully authenticates, returning the first successful
#' credential object.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to
#'   request a 'refresh_token'. Defaults to `TRUE`.
#' @param oauth_host Optional character string specifying the OAuth host URL.
#' @param oauth_endpoint Optional character string specifying the OAuth endpoint.
#' @param chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds. If `NULL`, uses
#'   [default_credential_chain()].
#' @param allow_interactive A logical value indicating whether interactive
#'   credentials are allowed. Defaults to [rlang::is_interactive()].
#' @param verbose A logical value indicating whether to print verbose messages
#'   during credential discovery. Defaults to the `chain_verbose` option, which
#'   reads `options(azr.chain_verbose = ...)` or the `AZR_CHAIN_VERBOSE`
#'   environment variable; see [azr_options()].
#' @param interactive Deprecated. Use `allow_interactive` instead.
#'
#' @return A credential object that inherits from the `Credential` class and
#'   has successfully authenticated.
#'
#' @seealso [get_token_provider()], [get_request_authorizer()],
#'   [default_credential_chain()]
#'
#' @examples
#' \dontrun{
#' # Get a credential provider with default settings
#' cred <- get_credential_provider(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "my-tenant-id"
#' )
#'
#' # Use the credential to get a token
#' token <- cred$get_token()
#' }
#'
#' @export
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
  allow_interactive = rlang::is_interactive(),
  verbose = opts$get("chain_verbose"),
  interactive = NULL
) {
  if (!is.null(interactive)) {
    deprecated_arg(
      "interactive",
      "allow_interactive",
      "get_credential_provider"
    )
    allow_interactive <- interactive
  }

  if (is.null(chain) || length(chain) == 0L) {
    chain <- default_credential_chain()
  }

  if (!inherits(chain, "credential_chain")) {
    cli::cli_abort(
      "Argument {.arg chain} must be of class {.cls credential_chain}."
    )
  }

  context <- build_credential_context(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    oauth_host = oauth_host,
    oauth_endpoint = oauth_endpoint
  )

  if (verbose) {
    ctx_lines <- vapply(names(context), function(nm) {
      val <- context[[nm]]
      if (nm == "client_secret") {
        paste0(nm, ": ", cli::col_grey("<<REDACTED>>"))
      } else {
        cli::format_inline("{nm}: {.val {val}}")
      }
    }, character(1))
    names(ctx_lines) <- rep(" ", length(ctx_lines))
    cli::cli_inform(c("i" = "Credential context:", ctx_lines))
  }

  errors <- list()

  for (i in seq_along(chain)) {
    crd_name <- names(chain)[i]
    if (is.null(crd_name) || !nzchar(crd_name)) {
      crd_name <- paste0("credential_", i)
    }

    if (verbose) {
      cli::cli_inform(c(
        "i" = "Trying credential {.strong {crd_name}} ({i}/{length(chain)})..."
      ))
    }

    built <- try_build_credential(
      chain[[i]],
      crd_name = crd_name,
      context = context,
      interactive = allow_interactive,
      verbose = verbose
    )

    if (is.null(built$obj)) {
      errors[[crd_name]] <- built$error
      next
    }

    obj <- built$obj

    if (verbose) {
      cli::cli_inform(c(
        " " = "Attempting to get token from {.strong {crd_name}}...",
        " " = "client_id: {.val {obj$.client_id}}, scope: {.val {obj$.scope}}"
      ))
    }

    token <- tryCatch(
      obj$get_token(),
      error = function(e) {
        errors[[crd_name]] <<- conditionMessage(e)
        NULL
      },
      interrupt = function(e) {
        errors[[crd_name]] <<- "Authentication interrupted by user"
        NULL
      }
    )

    if (inherits(token, "httr2_token")) {
      if (verbose) {
        cli::cli_inform(c(
          "v" = "Successfully authenticated with {.strong {crd_name}}."
        ))
      }
      return(obj)
    }

    if (verbose) {
      cli::cli_inform(c(
        "x" = "{.strong {crd_name}} failed: {errors[[crd_name]]}"
      ))
    }
  }

  # All credentials failed, report all errors
  error_msgs <- c(
    "All authentication methods in the chain failed!"
  )

  for (cred_name in names(errors)) {
    error_msgs <- c(
      error_msgs,
      "i" = paste0("{.strong ", cred_name, "}:"),
      "x" = errors[[cred_name]]
    )
  }

  cli::cli_abort(error_msgs, class = "azr_credential_chain_failed")
}

# Builds the explicit context passed to chain entries' constructors.
# `interactive` is deliberately excluded: it is chain-runner policy
# (see try_build_credential()), not a credential constructor argument, and
# must not override a credential's own interactivity defaults (e.g.
# AzureCLICredential's `cli_auto_login`).
# At provider level, NULL means "not configured": dropped so the
# constructor's own default applies.
build_credential_context <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  oauth_host = NULL,
  oauth_endpoint = NULL
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
  Filter(Negate(is.null), context)
}

try_build_credential <- function(
  entry,
  crd_name,
  context,
  interactive = rlang::is_interactive(),
  verbose = FALSE
) {
  fail <- function(error) {
    if (verbose) {
      cli::cli_inform(c("x" = "{.strong {crd_name}}: {error}"))
    }
    list(obj = NULL, error = error)
  }

  if (verbose) {
    if (inherits(entry, "azr_credential_spec")) {
      cli::cli_inform(c(
        " " = "Instantiating R6 class {.cls {entry$class$classname}}."
      ))
    } else {
      cli::cli_inform(c(
        " " = "Using existing R6 instance of class {.cls {class(entry)[1]}}."
      ))
    }
  }

  obj <- try(build_credential(entry, context = context), silent = TRUE)

  if (inherits(obj, "try-error")) {
    return(fail(conditionMessage(attr(obj, "condition"))))
  }

  if (!inherits(obj, "Credential")) {
    return(fail("Object does not inherit from Credential class"))
  }

  if (obj$is_interactive() && !interactive) {
    return(fail("Credential requires an interactive session"))
  }

  list(obj = obj, error = NULL)
}


#' Create Default Credential Chain
#'
#' Creates the default chain of credentials to attempt during authentication.
#' The credentials are tried in order until one successfully authenticates.
#' The default chain includes:
#' \enumerate{
#'   \item Client Secret Credential - Uses client ID and secret
#'   \item Authorization Code Credential - Interactive browser-based authentication
#'   \item Device Code Credential - Interactive device code flow
#'   \item Azure CLI Credential - Uses credentials from Azure CLI
#' }
#'
#' @return A `credential_chain` object containing the default sequence of
#'   credential providers.
#'
#' @seealso [credential_chain()], [get_token_provider()]
#'
#' @export
default_credential_chain <- function() {
  credential_chain(
    client_secret = ClientSecretCredential,
    workload_identity = WorkloadIdentityCredential,
    managed_identity = ManagedIdentityCredential,
    azure_cli = AzureCLICredential,
    auth_code = AuthCodeCredential,
    device_code = DeviceCodeCredential
  )
}


#' Create Custom Credential Chain
#'
#' Creates a custom chain of credential providers to attempt during
#' authentication. Credentials are tried in the order they are provided
#' until one successfully authenticates. This allows you to customize
#' the authentication flow beyond the default credential chain.
#'
#' @param ... Named chain entries. Each entry must be one of:
#'   * a credential class (e.g., `ClientSecretCredential`), equivalent to
#'     `credential_spec(ClientSecretCredential)`;
#'   * a [credential_spec()], for entries that need per-entry constructor
#'     arguments;
#'   * an already-constructed object that inherits from the `Credential` base
#'     class, used as-is with no context merge.
#'
#'   The names are used for identification purposes. Entries are validated and
#'   normalized immediately; constructing a chain performs no authentication.
#'
#' @return A `credential_chain` object containing the specified sequence
#'   of credential providers.
#'
#' @seealso [default_credential_chain()], [credential_spec()],
#'   [get_token_provider()]
#'
#' @examples
#' # Create a custom chain with only non-interactive credentials
#' custom_chain <- credential_chain(
#'   client_secret = ClientSecretCredential,
#'   azure_cli = AzureCLICredential
#' )
#'
#' # Use the custom chain to get a token
#' \dontrun{
#' token <- get_token(
#'   scope = "https://graph.microsoft.com/.default",
#'   chain = custom_chain
#' )
#' }
#'
#' @export
credential_chain <- function(...) {
  entries <- rlang::list2(...)

  if (length(entries) == 0L) {
    cli::cli_abort(
      c(
        "Credential chain cannot be empty.",
        "i" = "Provide at least one credential class, spec, or instance.",
        "i" = "Use {.fn default_credential_chain} for a pre-configured chain."
      )
    )
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
      "Chain entries must be a credential class, {.fn credential_spec}, or a {.cls Credential} instance."
    )
  })

  structure(entries, class = "credential_chain")
}

#' Print a credential chain
#'
#' @param x A `credential_chain` object.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @exportS3Method print credential_chain
print.credential_chain <- function(x, ...) {
  cli::cli_h1("credential_chain")

  nms <- names(x) %||% rep("", length(x))

  for (i in seq_along(x)) {
    entry <- x[[i]]
    nm <- nms[[i]]
    if (!nzchar(nm)) {
      nm <- paste0("[[", i, "]]")
    }

    label <- if (inherits(entry, "azr_credential_spec")) {
      format(entry)
    } else {
      cli::format_inline("<{class(entry)[[1]]}> (instance)")
    }

    cli::cli_text("{.field {nm}}: {label}")
  }

  invisible(x)
}

#' Specify a credential chain entry
#'
#' @description
#' Creates a chain entry that pairs a credential class with constructor
#' arguments to use for that entry, overriding the values that
#' [get_credential_provider()] would otherwise pass from its own context.
#'
#' @param class A `Credential` R6 class generator (e.g.,
#'   `ClientSecretCredential`).
#' @param ... Named arguments forwarded to `class$new()`. Each name must match
#'   a named argument of `class`'s `initialize()` method (excluding `...`).
#'   Validated immediately, so unknown or unnamed arguments fail when the spec
#'   is created.
#'
#' @return An object of class `azr_credential_spec`.
#'
#' @seealso [credential_chain()]
#' @export
credential_spec <- function(class, ...) {
  args <- rlang::list2(...)

  if (!R6::is.R6Class(class)) {
    cli::cli_abort(
      "{.arg class} must be an R6 credential class generator, not {.obj_type_friendly {class}}."
    )
  }

  if (length(args) > 0L && !rlang::is_named(args)) {
    cli::cli_abort("All arguments to {.fn credential_spec} must be named.")
  }

  accepted <- setdiff(r6_get_initialize_arguments(class), "...")
  unknown <- setdiff(names(args), accepted)
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "{cli::qty(length(unknown))}Unknown argument{?s} {.arg {unknown}} for {.cls {class$classname}}.",
      "i" = "Accepted: {.arg {accepted}}."
    ))
  }

  structure(
    list(class = class, args = args),
    class = "azr_credential_spec"
  )
}

# Pattern used to redact sensitive constructor arguments in
# format.azr_credential_spec(); matches names like client_secret,
# refresh_token, password, api_key, etc.
spec_sensitive_pattern <- "secret|token|password|key"

#' @param x An `azr_credential_spec` object.
#' @param ... Unused.
#' @rdname credential_spec
#' @exportS3Method format azr_credential_spec
format.azr_credential_spec <- function(x, ...) {
  shown <- x$args

  if (length(shown) == 0L) {
    return(cli::format_inline("<credential_spec: {x$class$classname}>"))
  }

  redact <- grepl(spec_sensitive_pattern, names(shown), ignore.case = TRUE)
  shown[redact] <- "<hidden>"

  args_str <- vapply(
    seq_along(shown),
    function(i) paste0(names(shown)[[i]], " = ", format_spec_value(shown[[i]])),
    character(1)
  )

  cli::format_inline(
    "<credential_spec: {x$class$classname}({paste(args_str, collapse = ', ')})>"
  )
}

#' @rdname credential_spec
#' @exportS3Method print azr_credential_spec
print.azr_credential_spec <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

# Formats a single credential_spec argument value for display. Strings are
# quoted; NULL renders as "NULL"; other values use format().
format_spec_value <- function(x) {
  if (is.null(x)) {
    return("NULL")
  }
  if (is.character(x)) {
    return(paste0("\"", x, "\""))
  }
  paste(format(x), collapse = ", ")
}

new_instance <- function(cls, context) {
  accepted <- setdiff(r6_get_initialize_arguments(cls), "...")
  args <- context[intersect(names(context), accepted)]
  rlang::exec(cls$new, !!!args)
}

# Builds a chain entry (a credential_spec() or pre-built instance) into a
# Credential object, merging the provider's context with the entry's own
# arguments. Entry arguments take precedence; pre-built instances are
# returned unchanged (no context merge: they are authoritative).
build_credential <- function(entry, context) {
  if (R6::is.R6(entry) && inherits(entry, "Credential")) {
    return(entry)
  }

  args <- context
  # List-RHS `[<-` preserves explicit NULL entry args. modifyList() would
  # *delete* them, silently re-enabling the constructor default.
  args[names(entry$args)] <- entry$args

  new_instance(entry$class, context = args)
}
