#' Azure API Client
#'
#' @description
#' An R6 class that provides a base HTTP client for interacting with Azure APIs.
#' This client handles authentication, request building, retry logic, logging,
#' and error handling for Azure API requests.
#'
#' @details
#' The `api_client` class is designed to be a base class for Azure service-specific
#' clients. It provides:
#' - Automatic authentication using Azure credentials
#' - Configurable retry logic with exponential backoff
#' - Request and response logging
#' - JSON, XML, and HTML content type handling
#' - Standardized error handling
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a client with default credentials
#' client <- api_client$new(
#'   host_url = "https://management.azure.com"
#' )
#'
#' # Create a client with custom credentials and options
#' client <- api_client$new(
#'   host_url = "https://management.azure.com",
#'   credentials = my_credential_function,
#'   timeout = 120,
#'   max_tries = 3
#' )
#'
#' # Make a GET request
#' response <- client$.request(
#'   path = "/subscriptions/{subscription_id}/resourceGroups",
#'   subscription_id = "my-subscription-id",
#'   req_method = "get"
#' )
#' }
api_client <- R6::R6Class(
  # nolint cyclocomp_linter
  classname = "api_client",
  cloneable = FALSE,
  # > public ----
  public = list(
    #' @field .host_url Base URL for the API
    .host_url = NULL,
    #' @field .base_req Base httr2 request object
    .base_req = NULL,
    #' @field .credentials Credentials function for authentication
    .credentials = NULL,
    #' @field .options Request options (timeout, connecttimeout, max_tries)
    .options = NULL,
    #' @description
    #' Create a new API client instance
    #'
    #' @param host_url A character string specifying the base URL for the API
    #'   (e.g., `"https://management.azure.com"`).
    #' @param credentials A function that adds authentication to requests. If
    #'   `NULL`, uses [default_non_auth()]. The function should accept
    #'   an httr2 request object and return a modified request with authentication.
    #' @param timeout An integer specifying the request timeout in seconds.
    #'   Defaults to `60`.
    #' @param connecttimeout An integer specifying the connection timeout in
    #'   seconds. Defaults to `30`.
    #' @param max_tries An integer specifying the maximum number of retry
    #'   attempts for failed requests. Defaults to `5`.
    #'
    #' @return A new `api_client` object
    initialize = function(
      host_url,
      credentials = NULL,
      timeout = 60L,
      connecttimeout = 30L,
      max_tries = 5L
    ) {
      if (!missing(host_url)) {
        self$.host_url <- host_url
      }

      self$.options <- list(
        timeout = timeout,
        connecttimeout = connecttimeout,
        max_tries = max_tries
      )
      stopifnot(
        !is.null(self$.host_url),
        length(self$.host_url) == 1L,
        is.character(self$.host_url)
      )

      if (is.null(credentials)) {
        credentials <- default_non_auth()
      }

      stopifnot(is.function(credentials))
      self$.credentials <- credentials

      self$.base_req <- httr2::request(self$.host_url) |>
        httr2::req_options(
          timeout = timeout,
          connecttimeout = connecttimeout
        ) |>
        httr2::req_retry(
          max_tries = max_tries,
          retry_on_failure = TRUE,
          backoff = function(i) {
            x <- backoff_default(i)
            cli::cli_alert_warning(
              "Request failed. Retrying in {.val {x}} secs. (attempt {i} of {self$.options$max_tries})."
            )
            return(x)
          }
        ) |>
        httr2::req_error(body = function(resp) {
          cli::cli_alert_danger(
            "<<< status={.val {resp$status}} | time={.val {format_timing(resp)}} secs."
          )

          if (httr2::resp_has_body(resp)) {
            txt <- httr2::resp_body_string(resp)
            cli::cli_alert_danger(txt)
          } else {
            txt <- ""
          }
          return(txt)
        })
    },
    #' @description
    #' Make an HTTP request to the API
    #'
    #' @param path A character string specifying the API endpoint path. Supports
    #'   [glue::glue()] syntax for variable interpolation using named arguments
    #'   passed via `...`.
    #' @param ... Named arguments used for path interpolation with [glue::glue()].
    #' @param req_data Request data. For GET requests, this is used as query
    #'   parameters. For other methods, this is sent as JSON in the request body.
    #'   Can be a list or character string (JSON).
    #' @param req_method A character string specifying the HTTP method. One of
    #'   `"get"`, `"post"`, `"put"`, `"patch"`, or `"delete"`. Defaults to `"get"`.
    #' @param verbosity An integer specifying the verbosity level for request
    #'   debugging (passed to [httr2::req_perform()]). Defaults to `0`.
    #' @param content A character string specifying what to return. One of:
    #'   - `"body"` (default): Return the parsed response body
    #'   - `"headers"`: Return response headers
    #'   - `"response"`: Return the full httr2 response object
    #'   - `"request"`: Return the prepared request object without executing it
    #' @param content_type A character string specifying how to parse the response
    #'   body. If `NULL`, uses the response's Content-Type header. Common values:
    #'   `"application/json"`, `"application/xml"`, `"text/html"`.
    #'
    #' @return Depends on the `content` parameter:
    #'   - `"body"`: Parsed response body (list, data.frame, or character)
    #'   - `"headers"`: List of response headers
    #'   - `"response"`: Full [httr2::response()] object
    #'   - `"request"`: [httr2::request()] object
    .fetch = function(
      path,
      ...,
      req_data = NULL,
      req_method = "get",
      verbosity = 0L,
      content = c("body", "headers", "response", "request"),
      content_type = NULL
    ) {
      content <- match.arg(content)

      req <- self$.req_build(
        path,
        ...,
        req_data = req_data,
        req_method = req_method
      )

      if (content == "request") {
        return(req)
      }

      resp <- self$.req_perform(req, verbosity = verbosity)

      switch(
        content,
        body = self$.resp_content(resp, content_type = content_type),
        headers = httr2::resp_headers(resp),
        response = resp
      )
    },
    #' @description
    #' Build an HTTP request object
    #'
    #' @param path A character string specifying the API endpoint path. Supports
    #'   [glue::glue()] syntax for variable interpolation using named arguments
    #'   passed via `...`.
    #' @param ... Named arguments used for path interpolation with [glue::glue()].
    #' @param req_data Request data. For GET requests, this is used as query
    #'   parameters. For other methods, this is sent as JSON in the request body.
    #'   Can be a list or character string (JSON).
    #' @param req_method A character string specifying the HTTP method. One of
    #'   `"get"`, `"post"`, `"put"`, `"patch"`, or `"delete"`. Defaults to `"get"`.
    #'
    #' @return An [httr2::request()] object ready for execution
    .req_build = function(path, ..., req_data = NULL, req_method = "get") {
      path <- glue::glue_data(list(...), path, .envir = emptyenv())

      req <- self$.base_req |>
        httr2::req_url_path_append(path) |>
        self$.credentials() |>
        httr2::req_method(req_method)

      if (!is.null(req_data)) {
        if (req_method == "get") {
          req <- httr2::req_url_query(req, !!!req_data)
        } else {
          if (!is.character(req_data)) {
            req_data <- jsonlite::toJSON(
              drop_null(req_data),
              null = "null",
              auto_unbox = TRUE
            )
          }
          stopifnot(length(req_data) == 1L)
          req <- httr2::req_body_raw(
            req,
            body = req_data,
            type = "application/json"
          )
        }
      }
      return(req)
    },
    #' @description
    #' Perform an HTTP request and log the results
    #'
    #' @param req An [httr2::request()] object to execute
    #' @param verbosity An integer specifying the verbosity level for request
    #'   debugging (passed to [httr2::req_perform()]). Defaults to `0`.
    #'
    #' @return An [httr2::response()] object containing the API response
    .req_perform = function(req, verbosity) {
      cli::cli_alert_info(">>> {.strong {req$method}} {.url {req$url}}")

      if (!is.null(req$body) && req$body$content_type == "application/json") {
        cli::cli_alert_info(">>> body:")
        cli::cli_verbatim(format_json_body(
          req$body$data,
          params = req$body$params
        ))
      }

      resp <- httr2::req_perform(req, verbosity = verbosity)

      size <- format_size(resp$body, units = "Kb")
      time <- format_timing(resp$timing)
      cli::cli_alert_success(
        "<<< status = {.val {resp$status}} | time = {time} secs. | size = {size} Kb"
      )

      return(resp)
    },
    #' @description
    #' Extract and parse response content
    #'
    #' @param resp An [httr2::response()] object
    #' @param content_type A character string specifying how to parse the response
    #'   body. If `NULL`, uses the response's Content-Type header. Common values:
    #'   `"application/json"`, `"application/xml"`, `"text/html"`.
    #'
    #' @return Parsed response body. Format depends on content type:
    #'   - JSON: List or data.frame
    #'   - XML: xml2 document
    #'   - HTML: xml2 document
    #'   - Other: Character string
    .resp_content = function(resp, content_type = NULL) {
      if (!httr2::resp_has_body(resp)) {
        stop("response has not body.", call. = FALSE)
      }

      if (is.null(content_type)) {
        content_type <- httr2::resp_content_type(resp)
      }

      ans <- switch(
        content_type,
        "application/json" = httr2::resp_body_json(
          resp,
          simplifyVector = TRUE,
          flatten = FALSE
        ),
        "application/xml" = httr2::resp_body_xml(resp),
        "text/html" = httr2::resp_body_html(resp),
        httr2::resp_body_string(resp)
      )

      if (is.list(ans)) {
        ans <- lapply(ans, function(x) {
          if (is.data.frame(x)) {
            data.table::as.data.table(x)
          } else {
            x
          }
        })
      }
      return(ans)
    }
  )
)


# utilities ----
backoff_default <- function(i, max_time = 60.0, b = 2.5) {
  round(min(stats::runif(1L, min = 1.0, max = b^i), max_time), digits = 1L)
}

format_timing <- function(timing) {
  y <- timing[["total"]]
  if (is.null(y) || is.na(y)) {
    cli::col_blue("???")
  } else {
    cli::format_inline("{.val {as.numeric(format(y, digits = 3L))}}")
  }
}

format_size <- function(body, units = "Kb") {
  x <- format(utils::object.size(body), units = units)
  cli::col_blue(strsplit(x, split = " ", fixed = TRUE)[[1]][1])
}

format_json_body <- function(x, params = NULL, max_size = 12L) {
  inner_format <- function(z) {
    lapply(z, function(i) {
      if (is.list(i)) {
        inner_format(i)
      } else if (length(i) > max_size) {
        c(utils::head(i), "...", utils::tail(i))
      } else {
        i
      }
    })
  }

  if (is.character(x)) {
    x <- jsonlite::fromJSON(x)
  }

  par_auto_box <- params$auto_unbox %||% TRUE
  par_null <- params$null %||% "null"

  res <- jsonlite::toJSON(
    inner_format(x),
    pretty = TRUE,
    auto_unbox = par_auto_box,
    null = par_null
  )
  res <- gsub("\\", "...", res, fixed = TRUE)

  return(res)
}

#' Default No Authentication
#'
#' @description
#' A pass-through credential function that performs no authentication.
#' This function returns the request object unchanged, allowing API calls
#' to be made without adding any authentication headers or tokens.
#'
#' @param req An [httr2::request()] object
#'
#' @return The same [httr2::request()] object, unmodified
#'
#' @export
default_non_auth <- function(req) {
  req
}

drop_null <- function(x) Filter(Negate(is.null), x)
