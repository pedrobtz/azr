#' Detect if running in a hosted session
#'
#' Determines whether the current R session is running in a hosted environment
#' such as Google Colab or RStudio Server (non-localhost).
#'
#' @return A logical value: `TRUE` if running in a hosted session (Google Colab
#'   or remote RStudio Server), `FALSE` otherwise.
#'
#' @details
#' This function checks for:
#' * Google Colab: presence of the `COLAB_RELEASE_TAG` environment variable
#' * RStudio Server: `RSTUDIO_PROGRAM_MODE` is "server" and
#'   `RSTUDIO_HTTP_REFERER` does not contain "localhost"
#'
#' @export
#' @examples
#' if (is_hosted_session()) {
#'   message("Running in a hosted environment")
#' }
is_hosted_session <- function() {
  # Check for Google Colab
  if (nzchar(Sys.getenv("COLAB_RELEASE_TAG"))) {
    return(TRUE)
  }

  # Check for RStudio Server (non-localhost)
  Sys.getenv("RSTUDIO_PROGRAM_MODE") == "server" &&
    !grepl("localhost", Sys.getenv("RSTUDIO_HTTP_REFERER"), fixed = TRUE)
}


bullets <- function(x) {
  as_simple <- function(x) {
    if (is.atomic(x) && length(x) == 1) {
      if (is.character(x)) {
        paste0("\"", x, "\"")
      } else {
        format(x)
      }
    } else {
      if (inherits(x, "redacted")) {
        format(x)
      } else {
        paste0("<", class(x)[[1L]], ">")
      }
    }
  }

  vals <- vapply(x, as_simple, character(1))
  names <- format(names(x))
  names <- gsub(" ", "\u00a0", names, fixed = TRUE) # non-breaking space

  for (i in seq_along(x)) {
    cli::cli_li("{.field {names[[i]]}}: {vals[[i]]}")
  }
  invisible(NULL)
}


list_redact <- function(x, names, case_sensitive = TRUE) {
  if (case_sensitive) {
    i <- match(names, names(x))
  } else {
    i <- match(tolower(names), tolower(names(x)))
  }
  i <- i[!is.na(i)]
  i <- setdiff(i, which(is_empty_vec(x)))
  x[i] <- list(redacted())
  x
}


redacted <- function() {
  structure(list(), class = "redacted")
}


#' @exportS3Method format redacted
format.redacted <- function(x, ...) {
  cli::col_grey("<REDACTED>")
}


#' @exportS3Method print redacted
print.redacted <- function(x, ...) {
  cat(format(x, ...), "\n", sep = "")
  invisible(x)
}

is_port_available <- function(port, host = "127.0.0.1") {
  # Try to connect to the port (if something is listening, connection succeeds)
  suppressWarnings(
    tryCatch(
      {
        con <- socketConnection(
          host = host,
          port = port,
          server = FALSE,
          blocking = TRUE,
          open = "r+",
          timeout = 1
        )
        close(con)
        # If connection succeeds, port is IN USE
        FALSE
      },
      error = function(e) {
        # If connection fails, port is AVAILABLE
        TRUE
      }
    )
  )
}

random_port <- function(
  min = 10000L,
  max = 49151L,
  host = "127.0.0.1",
  n = 20
) {
  min <- max(1L, min)
  max <- min(max, 65535L)
  try_ports <- sample(x = seq.int(min, max), n)
  for (port in try_ports) {
    if (is_port_available(port, host)) {
      return(port)
    }
  }
  cli::cli_abort("Cannot find an available port.")
}
