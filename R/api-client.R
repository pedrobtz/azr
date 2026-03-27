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
#' # Create a client with a credential provider
#' cred_provider <- get_credential_provider(
#'   scope = "https://management.azure.com/.default"
#' )
#' client <- api_client$new(
#'   host_url = "https://management.azure.com",
#'   provider = cred_provider
#' )
#'
#' # Create a client with custom credentials function
#' client <- api_client$new(
#'   host_url = "https://management.azure.com",
#'   credentials = my_credential_function,
#'   timeout = 120,
#'   max_tries = 3
#' )
#'
#' # Create a client with custom response handler
#' custom_handler <- function(content) {
#'   # Custom processing logic - e.g., keep data frames as-is
#'   content
#' }
#' client <- api_client$new(
#'   host_url = "https://management.azure.com",
#'   response_handler = custom_handler
#' )
#'
#' # Make a GET request
#' response <- client$.fetch(
#'   path = "/subscriptions/{subscription_id}/resourceGroups",
#'   subscription_id = "my-subscription-id",
#'   query = list(`api-version` = "2021-04-01"),
#'   method = "get"
#' )
#' }
api_client <- R6::R6Class(
  # nolint cyclocomp_linter
  classname = "api_client",
  cloneable = TRUE,
  # > public ----
  public = list(
    #' @field .host_url Base URL for the API
    .host_url = NULL,
    #' @field .base_req Base httr2 request object
    .base_req = NULL,
    #' @field .provider Credential provider R6 object
    .provider = NULL,
    #' @field .credentials Credentials function for authentication
    .credentials = NULL,
    #' @field .options Request options (timeout, connecttimeout, max_tries)
    .options = NULL,
    #' @field .response_handler Optional callback function to process response content
    .response_handler = NULL,
    #' @description
    #' Create a new API client instance
    #'
    #' @param host_url A character string specifying the base URL for the API
    #'   (e.g., `"https://management.azure.com"`).
    #' @param provider An R6 credential provider object that inherits from the
    #'   `Credential` or `DefaultCredential` class. If provided, the credential's
    #'   `req_auth` method will be used for authentication. Takes precedence over
    #'   `credentials`.
    #' @param credentials A function that adds authentication to requests. If
    #'   both `provider` and `credentials` are `NULL`, uses [default_non_auth()].
    #'   The function should accept an httr2 request object and return a modified
    #'   request with authentication.
    #' @param timeout An integer specifying the request timeout in seconds.
    #'   Defaults to `60`.
    #' @param connecttimeout An integer specifying the connection timeout in
    #'   seconds. Defaults to `30`.
    #' @param max_tries An integer specifying the maximum number of retry
    #'   attempts for failed requests. Defaults to `5`.
    #' @param response_handler An optional function to process the parsed response
    #'   content. The function should accept one argument (the parsed response) and
    #'   return the processed content. If `NULL`, uses [default_response_handler()]
    #'   which converts data frames to data.table objects. Defaults to `NULL`.
    #'
    #' @return A new `api_client` object
    initialize = function(
      host_url,
      provider = NULL,
      credentials = NULL,
      timeout = 60L,
      connecttimeout = 30L,
      max_tries = 5L,
      response_handler = NULL
    ) {
      if (!missing(host_url)) {
        self$.host_url <- host_url
      }

      self$.options <- list(
        timeout = timeout,
        connecttimeout = connecttimeout,
        max_tries = max_tries
      )
      if (is.null(self$.host_url)) {
        cli::cli_abort("Argument {.arg host_url} must not be NULL.")
      }
      if (length(self$.host_url) != 1L) {
        cli::cli_abort(
          "Argument {.arg host_url} must be a single value, not length {length(self$.host_url)}."
        )
      }
      if (!is.character(self$.host_url)) {
        cli::cli_abort(
          "Argument {.arg host_url} must be a character string, not {.cls {class(self$.host_url)}}."
        )
      }

      # Handle credentials function
      if (!is.null(credentials)) {
        if (!is.function(credentials)) {
          cli::cli_abort(
            "Argument {.arg credentials} must be a function, not {.cls {class(credentials)}}."
          )
        }
        self$.credentials <- credentials
      } else if (!is.null(provider)) {
        # Handle credential provider if provided
        if (
          !R6::is.R6(provider) ||
            !(inherits(provider, "Credential") ||
              inherits(provider, "DefaultCredential"))
        ) {
          cli::cli_abort(
            "Argument 'provider' must be an R6 object that inherits from 'Credential' or 'DefaultCredential' class."
          )
        }
        self$.provider <- provider
        self$.credentials <- function(req) provider$req_auth(req)
      } else {
        self$.credentials <- default_non_auth
      }

      # Handle response handler function
      if (is.null(response_handler)) {
        response_handler <- default_response_handler
      }

      stopifnot(is.function(response_handler))
      self$.response_handler <- response_handler

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
            "<<< status = {.val {resp$status}} | time = {format_timing(resp$timing)} secs."
          )
          if (httr2::resp_has_body(resp)) {
            err_content <- httr2::resp_body_string(resp)
            cli::cli_alert_danger("<<< body:")
            cli::cli_verbatim(err_content)
          }
          invisible()
        })

      # Lock all public fields to prevent modification
      lockBinding(".host_url", self)
      lockBinding(".base_req", self)
      lockBinding(".provider", self)
      lockBinding(".credentials", self)
      lockBinding(".options", self)
      lockBinding(".response_handler", self)
    },
    #' @description
    #' Make an HTTP request to the API
    #'
    #' @param path A character string specifying the API endpoint path. Supports
    #'   [rlang::englue()] syntax for variable interpolation using named arguments
    #'   passed via `...`.
    #' @param ... Named arguments used for path interpolation with [rlang::englue()].
    #' @param query A named list of query parameters to append to the URL.
    #' @param body Request body data. Sent as JSON in the request body.
    #'   Can be a list or character string (JSON).
    #' @param headers A named list of additional HTTP headers to include in the
    #'   request.
    #' @param method A character string specifying the HTTP method. One of
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
      query = NULL,
      body = NULL,
      headers = NULL,
      method = "get",
      verbosity = 0L,
      content = c("body", "headers", "response", "request"),
      content_type = NULL
    ) {
      content <- match.arg(content)

      req <- self$.build_request(
        path,
        ...,
        query = query,
        body = body,
        headers = headers,
        method = method
      )

      if (content == "request") {
        return(req)
      }

      resp <- self$.send_request(req, verbosity = verbosity)

      self$.resp_content(resp, content = content, content_type = content_type)
    },
    #' @description
    #' Extract content from a response object
    #'
    #' @param resp An [httr2::response()] object
    #' @param content A character string specifying what to return. One of:
    #'   - `"body"`: Return the parsed response body
    #'   - `"headers"`: Return response headers
    #'   - `"response"`: Return the full httr2 response object
    #' @param content_type A character string specifying how to parse the response
    #'   body. Only used when `content = "body"`. If `NULL`, uses the response's
    #'   Content-Type header.
    #'
    #' @return Depends on the `content` parameter:
    #'   - `"body"`: Parsed response body (list, data.frame, or character)
    #'   - `"headers"`: List of response headers
    #'   - `"response"`: Full [httr2::response()] object
    .resp_content = function(resp, content, content_type = NULL) {
      switch(
        content,
        body = self$.resp_body_content(resp, content_type = content_type),
        headers = httr2::resp_headers(resp),
        response = resp
      )
    },
    #' @description
    #' Build an HTTP request object
    #'
    #' @param path A character string specifying the API endpoint path. Supports
    #'   [rlang::englue()] syntax for variable interpolation using named arguments
    #'   passed via `...`.
    #' @param ... Named arguments used for path interpolation with [rlang::englue()].
    #' @param query A named list of query parameters to append to the URL.
    #' @param body Request body data. Sent as JSON in the request body.
    #'   Can be a list or character string (JSON).
    #' @param headers A named list of additional HTTP headers to include in the
    #'   request.
    #' @param method A character string specifying the HTTP method. One of
    #'   `"get"`, `"post"`, `"put"`, `"patch"`, or `"delete"`. Defaults to `"get"`.
    #'
    #' @return An [httr2::request()] object ready for execution
    .build_request = function(
      path,
      ...,
      query = NULL,
      body = NULL,
      headers = NULL,
      method = "get"
    ) {
      path <- rlang::englue(path, env = as.environment(list(...)))

      req <- self$.base_req |>
        httr2::req_url_path_append(path) |>
        httr2::req_method(method)

      if (!is.null(query)) {
        req <- httr2::req_url_query(req, !!!query)
      }

      if (!is.null(body)) {
        if (!is.character(body)) {
          body <- jsonlite::toJSON(
            drop_null(body),
            null = "null",
            auto_unbox = TRUE
          )
        }
        stopifnot(length(body) == 1L)
        req <- httr2::req_body_raw(
          req,
          body = body,
          type = "application/json"
        )
      }

      if (!is.null(headers)) {
        req <- httr2::req_headers(req, !!!headers)
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
    .send_request = function(req, verbosity) {
      cli::cli_alert_info(">>> {.strong {req$method}} {.url {req$url}}")

      if (!is.null(req$body) && req$body$content_type == "application/json") {
        cli::cli_alert_info(">>> body:")
        cli::cli_verbatim(format_json_body(
          req$body$data,
          params = req$body$params
        ))
      }

      resp <- httr2::req_perform(self$.credentials(req), verbosity = verbosity)

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
    .resp_body_content = function(resp, content_type = NULL) {
      if (!httr2::resp_has_body(resp)) {
        cli::cli_inform("Response has no body.")
        return(invisible(NULL))
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

      # Apply response handler callback
      ans <- self$.response_handler(ans)

      return(ans)
    },
    #' @description
    #' Get authentication token from the credential provider
    #'
    #' @return An [httr2::oauth_token()] object if a provider is available,
    #'   otherwise returns `NULL` with a warning.
    .get_token = function() {
      if (!is.null(self$.provider)) {
        return(self$.provider$get_token())
      } else {
        cli::cli_warn(
          "No credential provider available. Cannot retrieve token."
        )
        return(invisible(NULL))
      }
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

format_json_body <- function(x, params = NULL, max_size = 12L, max_items = 6L) {
  inner_format <- function(z) {
    if (length(z) > max_items) {
      z <- c(utils::head(z, 3), list("..."), utils::tail(z, 3))
    }
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

  par_auto_box <- params$auto_unbox %||% TRUE
  par_null <- params$null %||% "null"

  if (is.character(x)) {
    x <- jsonlite::fromJSON(
      x,
      simplifyDataFrame = FALSE,
      simplifyMatrix = FALSE
    )
  }

  res <- jsonlite::toJSON(
    inner_format(x),
    pretty = TRUE,
    auto_unbox = par_auto_box,
    null = par_null
  )
  res <- gsub("\\", "...", res, fixed = TRUE)
  res <- gsub('"..."', "...", res, fixed = TRUE)

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


try_as_data_table <- function(x) {
  tryCatch(
    data.table::as.data.table(x),
    error = function(e) {
      cli::cli_warn(c(
        "Failed to convert data.frame to data.table: {e$message}",
        "i" = "Returning original data.frame"
      ))
      x
    }
  )
}

#' Default response handler
#'
#' Converts `data.frame` results in the parsed response to `data.table` objects
#' when the `data.table` package is available. Applied automatically by
#' [api_client] unless overridden via the `response_handler` argument.
#'
#' @param content Parsed response content from an API call.
#'
#' @return The processed content, with any `data.frame` objects converted to
#'   `data.table` if the `data.table` package is installed.
#'
#' @export
default_response_handler <- function(content) {
  if (!rlang::is_installed("data.table")) {
    return(content)
  }
  if (is.data.frame(content)) {
    return(try_as_data_table(content))
  }
  if (is.list(content)) {
    content <- lapply(content, function(x) {
      if (is.data.frame(x)) try_as_data_table(x) else x
    })
  }
}

drop_null <- function(x) Filter(Negate(is.null), x)
