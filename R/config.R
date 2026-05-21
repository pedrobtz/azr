#' Read an azr package option
#'
#' @description
#' Retrieves the value of an azr package option by name, using the following
#' priority order:
#' 1. R option (e.g. `options(azr.chain_verbose = TRUE)`)
#' 2. Environment variable (e.g. `AZR_CHAIN_VERBOSE=true`)
#' 3. Built-in default
#'
#' @param name A character string naming the option. Must be one of the keys in
#'   [azr_options] (e.g. `"chain_verbose"`).
#'
#' @return The option value, coerced to the type of the built-in default.
#'
#' @export
#' @examples
#' azr_opt("chain_verbose")
azr_opt <- function(name) {
  spec <- azr_options[[name]]
  if (is.null(spec)) {
    cli::cli_abort("Unknown azr option: {.val {name}}")
  }

  val <- getOption(spec$option)
  if (!is.null(val)) {
    return(val)
  }

  env <- Sys.getenv(spec$env_var, unset = NA_character_)
  if (!is.na(env)) {
    return(coerce_env_value(env, spec$default))
  }

  spec$default
}

coerce_env_value <- function(value, default) {
  if (is.logical(default)) {
    toupper(value) %in% c("TRUE", "1", "YES")
  } else if (is.numeric(default)) {
    as.numeric(value)
  } else {
    value
  }
}

#' azr package options
#'
#' @description
#' Registry of all azr package options. Each option can be set via an R option
#' or an environment variable. Use [azr_opt()] to read an option value.
#'
#' | Name | R option | Env variable | Default | Description |
#' |------|----------|--------------|---------|-------------|
#' | `"chain_verbose"` | `azr.chain_verbose` | `AZR_CHAIN_VERBOSE` | `FALSE` | Verbose credential-chain discovery |
#' | `"api_verbose"` | `azr.api_verbose` | `AZR_API_VERBOSE` | `FALSE` | Verbose api_client request/response |
#' | `"cli_login_enable"` | `azr.cli_login_enable` | `AZR_CLI_LOGIN_ENABLE` | `FALSE` | Auto Azure CLI login |
#'
#' @export
#' @examples
#' # List all option specs
#' azr_options
#'
#' # Read with azr_opt()
#' azr_opt("chain_verbose")
#'
#' # Set for the session
#' options(azr.chain_verbose = TRUE)
#'
#' # Or via environment variable (before starting R)
#' # AZR_CHAIN_VERBOSE=true
azr_options <- list(
  chain_verbose = list(
    option = "azr.chain_verbose",
    env_var = "AZR_CHAIN_VERBOSE",
    default = FALSE
  ),
  api_verbose = list(
    option = "azr.api_verbose",
    env_var = "AZR_API_VERBOSE",
    default = FALSE
  ),
  cli_login_enable = list(
    option = "azr.cli_login_enable",
    env_var = "AZR_CLI_LOGIN_ENABLE",
    default = FALSE
  )
)
