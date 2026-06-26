#' Azure Log Analytics API Class
#'
#' @description
#' An R6 class that extends [api_client] to provide a Kusto Query Language
#' (KQL) `query()` method against the public Azure Log Analytics REST API,
#' bound to a specific Azure subscription and resource group at construction.
#'
#' @details
#' The client is bound to `subscription_id` and `resource_id` (the resource
#' group name) at construction. The `$query()` method issues a `POST` to
#' `https://{endpoint}/{api_version}/subscriptions/{subscription_id}/resourceGroups/{resource_id}/query`
#' with a JSON body (`{"query": ..., "timespan": ..., "workspaces": [...]}`).
#'
#' Pass `scope = "hierarchy"` (or any other supported query-string parameter)
#' via `...` on `$query()` to traverse the resource hierarchy.
#'
#' @export
#' @examples
#' \dontrun{
#' la <- api_log_analytics_client$new(
#'   subscription_id = "00000000-0000-0000-0000-000000000000",
#'   resource_id = "my-resource-group"
#' )
#'
#' la$query(
#'   query = "AzureDiagnostics | take 10",
#'   timespan = "PT12H",
#'   scope = "hierarchy"
#' )
#' }
api_log_analytics_client <- R6::R6Class(
  classname = "api_log_analytics_client",
  inherit = api_client,
  public = list(
    #' @field .subscription_id The Azure subscription ID the client is bound to.
    .subscription_id = NULL,
    #' @field .resource_id The Azure resource group name the client is bound to.
    .resource_id = NULL,
    #' @field .api_version The API version segment prepended to all query paths.
    .api_version = NULL,

    #' @description
    #' Create a new Azure Log Analytics API client instance bound to a specific
    #' subscription and resource group.
    #'
    #' @param subscription_id A character string specifying the Azure
    #'   subscription ID (GUID) to bind the client to.
    #' @param resource_id A character string specifying the Azure resource
    #'   group name to bind the client to.
    #' @param endpoint A character string specifying the Log Analytics query
    #'   endpoint host (e.g. `"api.loganalytics.io"`). Defaults to
    #'   [default_log_analytics_endpoint()]. Any leading `https?://` scheme or
    #'   trailing slashes are stripped.
    #' @param api_version A character string specifying the API version segment
    #'   prepended to the query path. Defaults to `"v1"`.
    #' @param scope A character string specifying the OAuth2 scope. Defaults to
    #'   `default_azure_scope("azure_log_analytics")`.
    #' @param provider An optional credential provider object that inherits from
    #'   `Credential` or `DefaultCredential`. If provided, `chain` is ignored.
    #' @param chain A [credential_chain] instance for authentication. If `NULL`,
    #'   a default credential chain is created using [DefaultCredential].
    #' @param tenant_id A character string specifying the Azure tenant ID. Passed
    #'   to [DefaultCredential] when `chain` is `NULL`.
    #' @param ... Additional arguments passed to the parent [api_client] constructor.
    #'
    #' @return A new `api_log_analytics_client` object
    initialize = function(
      subscription_id,
      resource_id,
      endpoint = default_log_analytics_endpoint(),
      api_version = "v1",
      scope = default_azure_scope("azure_log_analytics"),
      provider = NULL,
      chain = NULL,
      tenant_id = NULL,
      ...
    ) {
      if (
        missing(subscription_id) ||
          !is.character(subscription_id) ||
          length(subscription_id) != 1L ||
          !nzchar(subscription_id)
      ) {
        cli::cli_abort(
          "{.arg subscription_id} must be a non-empty character string."
        )
      }
      if (
        missing(resource_id) ||
          !is.character(resource_id) ||
          length(resource_id) != 1L ||
          !nzchar(resource_id)
      ) {
        cli::cli_abort(
          "{.arg resource_id} must be a non-empty character string."
        )
      }
      if (
        !is.character(api_version) ||
          length(api_version) != 1L ||
          !nzchar(api_version)
      ) {
        cli::cli_abort(
          "{.arg api_version} must be a non-empty character string."
        )
      }

      host_url <- log_analytics_host_url(endpoint)

      base_req <- httr2::request(host_url) |>
        httr2::req_url_path_append(
          api_version,
          "subscriptions",
          subscription_id,
          "resourceGroups",
          resource_id
        )
      host_url <- base_req$url

      scope <- collapse_scope(scope)

      if (is.null(provider)) {
        provider <- DefaultCredential$new(
          scope = scope,
          chain = chain,
          tenant_id = tenant_id,
          client_id = default_azure_cli_client_id()
        )
      } else if (!is_credential(provider)) {
        cli::cli_abort(
          "Argument {.arg provider} must inherit from {.cls Credential},
          {.cls DefaultCredential}, or {.cls CachedTokenCredential}."
        )
      }

      self$.subscription_id <- subscription_id
      self$.resource_id <- resource_id
      self$.api_version <- api_version

      super$initialize(host_url = host_url, provider = provider, ...)

      lockBinding(".subscription_id", self)
      lockBinding(".resource_id", self)
      lockBinding(".api_version", self)
    },

    #' @description
    #' Issue a KQL query against the bound subscription and resource group.
    #'
    #' @param query A character string containing the KQL query to execute.
    #' @param date_from Start of the time range as a `Date` or `POSIXct`. When
    #'   provided together with `date_to`, appends
    #'   `| where TimeGenerated between(datetime(...), datetime(...))` to the
    #'   query and sets `timespan` to `NULL`. Defaults to `Sys.Date() - 3`.
    #' @param date_to End of the time range as a `Date` or `POSIXct`. Defaults
    #'   to `Sys.Date() + 1`.
    #' @param timespan An ISO 8601 duration (e.g. `"PT12H"`) or start/end pair
    #'   separated by `/` (e.g. `"2024-01-01/2024-01-02"`). Passed as a URL
    #'   query parameter. Ignored when `date_from` and `date_to` are set.
    #'   Defaults to `NULL`.
    #' @param max_rows Maximum number of rows to return. Defaults to `500001`.
    #' @param options A named list of query options. Defaults to
    #'   `list(truncationMaxSize = 67108864)`.
    #' @param workspace_filters A named list of workspace filters. Defaults to
    #'   `list(regions = list())`.
    #' @param ... Additional URL query parameters. Override defaults (e.g.
    #'   `scope = "resource"` to change from the default `"hierarchy"`).
    #' @param raw If `TRUE`, returns the parsed JSON response as a list. If
    #'   `FALSE` (the default), returns a named list of `data.frame`s — one per
    #'   table in the response — or the single table directly if only one is
    #'   returned.
    #' @param coerce_types If `TRUE` (the default), columns are coerced to their
    #'   native R types based on the Log Analytics schema (e.g. `datetime` →
    #'   `POSIXct`, `bool` → `logical`). Set to `FALSE` to keep all values as
    #'   character.
    #'
    #' @return Either a single `data.frame`, a named list of `data.frame`s, or
    #'   the raw parsed response (when `raw = TRUE`).
    query = function(
      query,
      date_from = Sys.Date() - 3,
      date_to = Sys.Date() + 1,
      timespan = NULL,
      max_rows = 500001L,
      options = list(truncationMaxSize = 67108864L),
      workspace_filters = list(regions = list()),
      ...,
      raw = FALSE,
      coerce_types = TRUE
    ) {
      if (
        missing(query) ||
          !is.character(query) ||
          length(query) != 1L ||
          !nzchar(query)
      ) {
        cli::cli_abort("{.arg query} must be a non-empty character string.")
      }

      if (!is.null(date_from) && !is.null(date_to)) {
        query <- paste0(
          query,
          "\n| where TimeGenerated between(datetime(",
          date_from,
          ") .. datetime(",
          date_to,
          "))"
        )
        timespan <- NULL
      }

      body <- list(
        query = query,
        maxRows = max_rows,
        options = options,
        workspaceFilters = workspace_filters
      )

      query_params <- utils::modifyList(
        list(timespan = timespan, scope = "hierarchy"),
        list(...)
      )
      query_params <- Filter(Negate(is.null), query_params)

      resp <- self$.fetch(
        path = "query",
        method = "post",
        body = body,
        query = query_params,
        content = "response"
      )

      parsed <- httr2::resp_body_json(resp, simplifyVector = FALSE)

      if (!is.null(parsed$error)) {
        cli::cli_abort(parsed$error$message)
      }

      if (isTRUE(raw)) {
        return(parsed)
      }

      log_analytics_parse_tables(parsed, coerce_types = coerce_types)
    }
  )
)

log_analytics_host_url <- function(endpoint) {
  if (!is.character(endpoint) || length(endpoint) != 1L) {
    cli::cli_abort("{.arg endpoint} must be a single character string.")
  }
  endpoint <- sub("^https?://", "", endpoint)
  endpoint <- sub("/+$", "", endpoint)
  if (!nzchar(endpoint)) {
    cli::cli_abort("{.arg endpoint} must be a non-empty character string.")
  }
  paste0("https://", endpoint)
}

log_analytics_parse_tables <- function(parsed, coerce_types = TRUE) {
  tables <- parsed$tables
  if (is.null(tables) || length(tables) == 0L) {
    return(list())
  }

  result <- lapply(
    tables,
    log_analytics_table_to_df,
    coerce_types = coerce_types
  )
  names(result) <- vapply(
    tables,
    function(t) t$name %||% NA_character_,
    character(1L)
  )

  if (length(result) == 1L) {
    return(result[[1L]])
  }
  result
}

log_analytics_table_to_df <- function(tbl, coerce_types = TRUE) {
  col_names <- vapply(tbl$columns, `[[`, character(1L), "name")
  col_types <- vapply(tbl$columns, `[[`, character(1L), "type")

  if (length(tbl$rows) == 0L) {
    cols <- lapply(col_types, function(t) {
      log_analytics_coerce_column(list(), if (coerce_types) t else "string")
    })
    names(cols) <- col_names
    df <- as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
    if (rlang::is_installed("data.table")) {
      return(data.table::as.data.table(df))
    }
    return(df)
  }

  cols <- lapply(seq_along(col_names), function(j) {
    values <- lapply(tbl$rows, function(row) row[[j]])
    log_analytics_coerce_column(
      values,
      if (coerce_types) col_types[[j]] else "string"
    )
  })
  names(cols) <- col_names
  df <- as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
  if (rlang::is_installed("data.table")) {
    return(data.table::as.data.table(df))
  }
  df
}

log_analytics_coerce_column <- function(values, type) {
  switch(
    type,
    "int" = ,
    "long" = vapply(
      values,
      function(v) if (is.null(v)) NA_integer_ else as.integer(v),
      integer(1L)
    ),
    "real" = ,
    "double" = ,
    "decimal" = vapply(
      values,
      function(v) if (is.null(v)) NA_real_ else as.numeric(v),
      numeric(1L)
    ),
    "bool" = ,
    "boolean" = vapply(
      values,
      function(v) if (is.null(v)) NA else as.logical(v),
      logical(1L)
    ),
    "datetime" = {
      x <- vapply(
        values,
        function(v) if (is.null(v)) NA_character_ else as.character(v),
        character(1L)
      )
      as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
    },
    vapply(
      values,
      function(v) {
        if (is.null(v)) {
          NA_character_
        } else if (is.list(v) || length(v) > 1L) {
          as.character(jsonlite::toJSON(v, auto_unbox = TRUE, null = "null"))
        } else {
          as.character(v)
        }
      },
      character(1L)
    )
  )
}

#' Create an Azure Log Analytics Client
#'
#' @description
#' A convenience wrapper around [api_log_analytics_client] that creates a
#' configured client for the Azure Log Analytics query REST API, bound to a
#' specific subscription and resource group.
#'
#' @param subscription_id A character string specifying the Azure subscription
#'   ID (GUID) to bind the client to.
#' @param resource_id A character string specifying the Azure resource group
#'   name to bind the client to.
#' @param endpoint A character string specifying the Log Analytics query
#'   endpoint host. Defaults to [default_log_analytics_endpoint()].
#' @param api_version A character string specifying the API version segment.
#'   Defaults to `"v1"`.
#' @param scope A character string specifying the OAuth2 scope. Defaults to
#'   `default_azure_scope("azure_log_analytics")`.
#' @param provider An optional credential provider object that inherits from
#'   `Credential` or `DefaultCredential`. If provided, `chain` is ignored.
#' @param chain A [credential_chain] instance for authentication. Defaults to
#'   [default_credential_chain()].
#' @param tenant_id A character string specifying the Azure tenant ID. Defaults
#'   to [default_azure_tenant_id()].
#' @param ... Additional arguments passed to the [api_log_analytics_client]
#'   constructor.
#'
#' @return An [api_log_analytics_client] object.
#'
#' @export
#' @examples
#' \dontrun{
#' la <- azr_logs_client(
#'   subscription_id = "00000000-0000-0000-0000-000000000000",
#'   resource_id = "my-resource-group"
#' )
#'
#' la$query(
#'   query = "AzureDiagnostics | take 10",
#'   timespan = "PT12H",
#'   scope = "hierarchy"
#' )
#' }
azr_logs_client <- function(
  subscription_id,
  resource_id,
  endpoint = default_log_analytics_endpoint(),
  api_version = "v1",
  scope = default_azure_scope("azure_log_analytics"),
  provider = NULL,
  chain = default_credential_chain(),
  tenant_id = default_azure_tenant_id(),
  ...
) {
  api_log_analytics_client$new(
    subscription_id = subscription_id,
    resource_id = resource_id,
    endpoint = endpoint,
    api_version = api_version,
    scope = scope,
    provider = provider,
    chain = chain,
    tenant_id = tenant_id,
    ...
  )
}
