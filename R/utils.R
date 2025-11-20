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


get_scope_resource <- function(scope) {
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


get_env_config <- function() {
  tenant_id_env <- Sys.getenv("AZURE_TENANT_ID", unset = "")
  client_id_env <- Sys.getenv("AZURE_CLIENT_ID", unset = "")
  client_secret_env <- Sys.getenv("AZURE_CLIENT_SECRET", unset = "")
  authority_host_env <- Sys.getenv("AZURE_AUTHORITY_HOST", unset = "")

  # Build bullet items
  c(
    "*" = if (nzchar(tenant_id_env)) {
      cli::format_inline("AZURE_TENANT_ID: {.val {tenant_id_env}}")
    } else {
      cli::format_inline(
        "AZURE_TENANT_ID: {.val {default_azure_tenant_id()}} (default)"
      )
    },
    "*" = if (nzchar(client_id_env)) {
      cli::format_inline("AZURE_CLIENT_ID: {.val {client_id_env}}")
    } else {
      cli::format_inline(
        "AZURE_CLIENT_ID: {.val {default_azure_client_id()}} (default)"
      )
    },
    "*" = if (nzchar(client_secret_env)) {
      paste0("AZURE_CLIENT_SECRET: ", cli::col_grey("<<REDACTED>>"))
    } else {
      paste0("AZURE_CLIENT_SECRET: ", cli::col_grey("(not set)"))
    },
    "*" = if (nzchar(authority_host_env)) {
      cli::format_inline("AZURE_AUTHORITY_HOST: {.val {authority_host_env}}")
    } else {
      cli::format_inline(
        "AZURE_AUTHORITY_HOST: {.val {default_azure_host()}} (default)"
      )
    }
  )
}
