# Package option registry.
# Each entry: value (set via opts$set), env (env var name), default (built-in
# fallback), and an optional type used to coerce string/env-var inputs.
# opts$get() resolution order: value -> options(azr.*) -> Sys.getenv(env) -> default
opts <- local({
  .spec <- list2env(
    list(
      chain_verbose = list(
        value = NULL,
        env = "AZR_CHAIN_VERBOSE",
        type = "logical",
        default = FALSE
      ),
      api_verbose = list(
        value = NULL,
        env = "AZR_API_VERBOSE",
        type = "logical",
        default = FALSE
      ),
      cli_auto_login = list(
        value = NULL,
        env = "AZR_CLI_AUTO_LOGIN",
        type = "logical",
        default = FALSE
      )
    ),
    parent = emptyenv()
  )

  .sentinel <- new.env(parent = emptyenv())

  coerce <- function(name, value) {
    spec <- .spec[[name]]
    type <- spec$type
    if (is.null(type)) {
      return(value)
    }

    if (type == "logical") {
      if (rlang::is_bool(value)) {
        return(value)
      }
      if (rlang::is_string(value)) {
        value <- tolower(value)
        if (value %in% c("true", "t", "1", "yes", "y")) {
          return(TRUE)
        }
        if (value %in% c("false", "f", "0", "no", "n")) {
          return(FALSE)
        }
      }
      cli::cli_abort(c(
        "Invalid value for {.pkg azr} option {.val {name}}.",
        i = "Expected {.code TRUE}/{.code FALSE}, or set {.envvar {spec$env}} to
          one of {.val true}/{.val false}, {.val 1}/{.val 0}, {.val yes}/{.val no}."
      ))
    }

    cli::cli_abort(
      "Option {.val {name}} has an unsupported type: {.val {type}}."
    )
  }

  # Resolve a name to its value and the source it came from, following the
  # precedence value -> options(azr.*) -> env var -> built-in default.
  resolve <- function(name) {
    spec <- .spec[[name]]
    if (!is.null(spec$value)) {
      return(list(value = coerce(name, spec$value), source = "set"))
    }
    opt <- getOption(paste0("azr.", name), NULL)
    if (!is.null(opt)) {
      return(list(value = coerce(name, opt), source = "option"))
    }
    env <- Sys.getenv(spec$env, unset = "")
    if (nzchar(env)) {
      return(list(value = coerce(name, env), source = "envvar"))
    }
    list(value = coerce(name, spec$default), source = "default")
  }

  get <- function(name, default = .sentinel) {
    spec <- .spec[[name]]
    if (is.null(spec)) {
      cli::cli_abort(c(
        "Unknown {.pkg azr} option: {.val {name}}.",
        i = "Available options: {.val {ls(.spec)}}."
      ))
    }
    res <- resolve(name)
    if (res$source == "default" && !identical(default, .sentinel)) {
      return(default)
    }
    res$value
  }

  set <- function(name, value = NULL) {
    if (is.null(.spec[[name]])) {
      cli::cli_abort(c(
        "Unknown {.pkg azr} option: {.val {name}}.",
        i = "Available options: {.val {ls(.spec)}}."
      ))
    }
    entry <- .spec[[name]]
    entry$value <- value
    .spec[[name]] <- entry
    invisible(value)
  }

  reset <- function() {
    for (nm in ls(.spec)) {
      entry <- .spec[[nm]]
      entry$value <- NULL
      .spec[[nm]] <- entry
    }
    invisible(NULL)
  }

  # Resolved view of every option: its current value, where that value came
  # from, the env var that can override it (and its raw value), and the
  # built-in default. Values are formatted to a single string for display —
  # multi-valued options are comma-joined, unset is NA.
  format_value <- function(v) {
    if (is.null(v) || length(v) == 0L) {
      return(NA_character_)
    }
    paste(as.character(v), collapse = ", ")
  }
  list_all <- function() {
    names <- ls(.spec)
    res <- lapply(names, resolve)
    env_vars <- vapply(names, function(n) .spec[[n]]$env, character(1))
    env_raw <- Sys.getenv(env_vars, unset = NA_character_)
    data.frame(
      option = names,
      value = vapply(res, function(r) format_value(r$value), character(1)),
      source = vapply(res, `[[`, character(1), "source"),
      env_var = unname(env_vars),
      env_value = unname(env_raw),
      default = unname(vapply(
        names,
        function(n) format_value(.spec[[n]]$default),
        character(1)
      )),
      stringsAsFactors = FALSE
    )
  }

  structure(
    list(
      get = get,
      set = set,
      reset = reset,
      list = list_all,
      .names = ls(.spec)
    ),
    class = "azr_opts"
  )
})

# Replace the value/env_value/default of sensitive options with "<hidden>".
mask_azr_opts <- function(tbl, mask) {
  if (!mask) {
    return(tbl)
  }
  sensitive <- character()
  for (col in c("value", "env_value", "default")) {
    hit <- tbl$option %in% sensitive & !is.na(tbl[[col]])
    tbl[[col]][hit] <- "<hidden>"
  }
  tbl
}

#' Print the azr option registry
#'
#' Renders one row per option with its current (resolved) value, the source
#' that value came from, the environment variable that can override it (and
#' whether it is set), and the built-in default.
#'
#' @param x An `azr_opts` object (the internal `opts` registry).
#' @param mask Logical. When `TRUE` (default), sensitive option values are
#'   shown as `"<hidden>"` when set.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @exportS3Method print azr_opts
print.azr_opts <- function(x, mask = TRUE, ...) {
  out <- mask_azr_opts(x$list(), mask)

  # Unset values render as a grey "(not set)"; set values are styled as {.val}.
  fmt_field <- function(v) {
    if (is.na(v)) {
      cli::col_grey("(not set)")
    } else {
      cli::format_inline("{.val {v}}")
    }
  }

  cli::cli_h1("azr options")
  for (i in seq_len(nrow(out))) {
    option <- out$option[[i]]
    source <- out$source[[i]]
    value <- fmt_field(out$value[[i]])
    env_var <- out$env_var[[i]]
    env_value <- fmt_field(out$env_value[[i]])

    # Values straight from the built-in default get a grey "(default)" marker
    # rather than a redundant line repeating the default.
    suffix <- if (source == "default") {
      cli::col_grey("(default)")
    } else {
      cli::format_inline("{.emph [{source}]}")
    }

    # Render verbatim (not via cli_text) so long values aren't reflowed onto a
    # second line when they exceed the console width.
    cli::cli_verbatim(
      cli::format_inline("{.field {option}} = {value} {suffix}")
    )
    cli::cli_verbatim(
      cli::format_inline("  {.envvar {env_var}}: {env_value}")
    )
  }

  invisible(x)
}

#' List all azr options and their current values
#'
#' @description
#' Prints every azr option (via [print.azr_opts()]) and invisibly returns a
#' [data.frame] of the same information. The resolution order is: a value set
#' for the session -> `options(azr.*)` -> the option's environment variable ->
#' a built-in default.
#'
#' | Name | R option | Env variable | Default | Description |
#' |------|----------|--------------|---------|-------------|
#' | `"chain_verbose"` | `azr.chain_verbose` | `AZR_CHAIN_VERBOSE` | `FALSE` | Verbose credential-chain discovery |
#' | `"api_verbose"` | `azr.api_verbose` | `AZR_API_VERBOSE` | `FALSE` | Verbose api_client request/response |
#' | `"cli_auto_login"` | `azr.cli_auto_login` | `AZR_CLI_AUTO_LOGIN` | `FALSE` | Auto Azure CLI login |
#'
#' @param mask Logical. When `TRUE` (default), sensitive option values are
#'   shown as `"<hidden>"` when set.
#' @return Invisibly, a [data.frame] with columns `option`, `value`, `source`,
#'   `env_var`, `env_value`, and `default`.
#' @export
#' @examples
#' azr_options()
#'
#' # Set for the session
#' options(azr.chain_verbose = TRUE)
#'
#' # Or via environment variable (before starting R)
#' # AZR_CHAIN_VERBOSE=true
azr_options <- function(mask = TRUE) {
  if (!rlang::is_bool(mask)) {
    cli::cli_abort("{.arg mask} must be `TRUE` or `FALSE`.")
  }
  print(opts, mask = mask)
  invisible(mask_azr_opts(opts$list(), mask))
}
