# Warns that `old_name` is a deprecated alias for `new_name` on `fn_name`.
deprecated_arg <- function(old_name, new_name, fn_name) {
  rlang::warn(
    c(
      paste0(
        "The `", old_name, "` argument to `", fn_name,
        "()` is deprecated."
      ),
      i = paste0("Use `", new_name, "` instead.")
    ),
    class = "azr_deprecated_argument"
  )
}


validate_tenant_id <- function(x) {
  if (!rlang::is_string(x)) {
    cli::cli_abort(
      "{.arg x} must be a single string, not {.obj_type_friendly {x}}"
    )
  }

  if (!grepl("^[A-Za-z0-9.-]+$", x)) {
    cli::cli_abort("Tenant ID {.val {x}} is not valid")
  }

  invisible(TRUE)
}


validate_scope <- function(x) {
  if (!rlang::is_character(x)) {
    cli::cli_abort(
      "{.arg x} must be a character vector, not {.obj_type_friendly {x}}"
    )
  }

  invalid <- !grepl("^[A-Za-z0-9_.:/-]+$", x)
  if (any(invalid)) {
    cli::cli_abort("Scope {.val {x[invalid]}} is not valid")
  }

  invisible(TRUE)
}


validate_required_string <- function(x, arg) {
  if (is.null(x) || length(x) == 0L || (length(x) == 1L && is.na(x))) {
    cli::cli_abort("Argument {.arg {arg}} cannot be NULL or NA.")
  }

  if (!is.character(x) || length(x) != 1L) {
    cli::cli_abort(
      "Argument {.arg {arg}} must be a single string, not {.obj_type_friendly {x}}."
    )
  }

  if (!nzchar(x)) {
    cli::cli_abort("Argument {.arg {arg}} cannot be empty.")
  }

  invisible(TRUE)
}


validate_use_cache <- function(x) {
  if (!is.character(x) || length(x) != 1L || is.na(x) ||
    !x %in% c("disk", "memory")) {
    cli::cli_abort(
      "Argument {.arg use_cache} must be one of {.val disk} or {.val memory}."
    )
  }

  invisible(TRUE)
}


get_scope_resource <- function(scope) {
  if (!is.character(scope)) {
    return(NULL)
  }

  x <- grep("^http", scope, value = TRUE, ignore.case = TRUE)

  if (length(x) != 1L) {
    return(NULL)
  }

  u <- httr2::url_parse(x)
  u$path <- NULL
  u$query <- NULL
  u$fragment <- NULL

  res <- httr2::url_build(u)
  sub("/$", "", res)
}


r6_get_initialize_arguments <- function(cls) {
  if (is.null(cls)) {
    return(NULL)
  }

  if (!R6::is.R6Class(cls)) {
    cli::cli_abort(
      "{.arg cls} must be an R6 class, not {.obj_type_friendly {cls}}"
    )
  }

  if (is.null(cls$public_methods$initialize)) {
    return(r6_get_initialize_arguments(cls$get_inherit()))
  }

  names(formals(cls$public_methods$initialize))
}


r6_get_public_fields <- function(cls) {
  if (!R6::is.R6Class(cls)) {
    cli::cli_abort(
      "{.arg cls} must be an R6 class, not {.obj_type_friendly {cls}}"
    )
  }

  res <- names(cls$public_fields)
  sup <- cls$get_inherit()

  if (!is.null(sup)) {
    return(c(res, r6_get_public_fields(sup)))
  }

  res
}


r6_get_class <- function(obj, envir = rlang::caller_env()) {
  if (!R6::is.R6(obj)) {
    cli::cli_abort(
      "{.arg obj} must be an R6 object, not {.obj_type_friendly {obj}}"
    )
  }
  get(class(obj)[[1]], envir = envir)
}


is_empty <- function(x) {
  is.null(x) ||
    (rlang::is_scalar_vector(x) &&
      (rlang::is_empty(x) || is.na(x) || !nzchar(x)))
}


is_empty_vec <- function(x) {
  vapply(x, is_empty, logical(1), USE.NAMES = FALSE)
}


# Sentinel used in place of a secret's value; the banner never shows it verbatim.
redacted_value <- "<<REDACTED>>"

#' Report the Azure environment configuration
#'
#' @description
#' Reports the Azure environment variables used during credential discovery,
#' the value each one resolves to, and where that value came from. This is the
#' same information shown in the package startup banner.
#'
#' `AZURE_CLIENT_SECRET` is never reported verbatim: when it is set, its value
#' is returned as `<<REDACTED>>`.
#'
#' @return A `data.frame` with one row per environment variable and the
#'   columns:
#'   \describe{
#'     \item{`variable`}{Name of the environment variable.}
#'     \item{`value`}{The resolved value, or `NA` when the variable is unset
#'       and has no built-in fallback.}
#'     \item{`source`}{Where the value came from: `"env"` when read from the
#'       environment, `"default"` when it falls back to a built-in value, or
#'       `"unset"` when the variable is not set and has no fallback.}
#'   }
#'
#' @seealso [default_azure_tenant_id()], [default_azure_client_id()],
#'   [default_azure_config_dir()]
#'
#' @export
#' @examples
#' az_config()
#'
#' # which variables are actually set in the environment?
#' config <- az_config()
#' config[config$source == "env", ]
az_config <- function() {
  entry <- function(variable, default = NULL, secret = FALSE) {
    env_val <- Sys.getenv(variable, unset = "")

    if (nzchar(env_val)) {
      source <- "env"
      value <- env_val
    } else if (!is.null(default)) {
      source <- "default"
      value <- default
    } else {
      source <- "unset"
      value <- NA_character_
    }

    if (secret && !is.na(value)) {
      value <- redacted_value
    }

    data.frame(
      variable = variable,
      value = value,
      source = source,
      stringsAsFactors = FALSE
    )
  }

  rbind(
    entry("AZURE_TENANT_ID", default = azure_client$tenant_id),
    entry("AZURE_CLIENT_ID", default = azure_client$client_id),
    entry("AZURE_CLIENT_SECRET", secret = TRUE),
    entry(
      "AZURE_AUTHORITY_HOST",
      default = azure_authority_hosts$azure_public_cloud
    ),
    entry("AZURE_CONFIG_DIR", default = default_azure_config_dir()),
    entry("AZURE_FEDERATED_TOKEN_FILE")
  )
}


# Renders az_config() as cli bullets for the startup banner. Values sourced
# from the environment are marked with a check; secrets stay redacted.
format_az_config <- function(config = az_config()) {
  bullets <- vapply(
    seq_len(nrow(config)),
    function(i) {
      variable <- config$variable[[i]]
      value <- config$value[[i]]

      if (config$source[[i]] == "unset") {
        return(paste0(variable, ": ", cli::col_grey("(not set)")))
      }

      shown <- if (identical(value, redacted_value)) {
        paste0(variable, ": ", cli::col_grey(value))
      } else {
        cli::format_inline("{variable}: {.val {value}}")
      }

      if (config$source[[i]] == "env") {
        paste0(
          shown,
          " ",
          cli::col_grey("(env)"),
          " ",
          cli::col_green("\u2713")
        )
      } else {
        paste0(shown, " ", cli::col_grey("(default)"))
      }
    },
    character(1)
  )

  stats::setNames(bullets, rep("*", length(bullets)))
}
