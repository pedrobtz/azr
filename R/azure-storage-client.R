#' Azure Storage API Class
#'
#' @description
#' An R6 class that extends [api_client] to provide specialized methods
#' for Azure Data Lake Storage Gen2 (ADLS Gen2) REST API operations.
#'
#' @details
#' The base URL is constructed as:
#' `https://{storageaccount}.{endpoint_suffix}`
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a storage client
#' storage <- api_storage_client$new(
#'   storageaccount = "mystorageaccount",
#'   filesystem = "mycontainer"
#' )
#'
#' # List files in the root directory
#' files <- storage$list_files()
#'
#' # List files in a specific path
#' files <- storage$list_files(path = "data/folder1")
#'
#' # List files recursively
#' files <- storage$list_files(path = "data", recursive = TRUE)
#' }
api_storage_client <- R6::R6Class(
  classname = "api_storage_client",
  inherit = api_client,
  public = list(
    #' @field .filesystem The filesystem (container) name
    .filesystem = NULL,

    #' @description
    #' Create a new Azure Storage API client instance
    #'
    #' @param storageaccount A character string specifying the Azure Storage account name.
    #' @param filesystem A character string specifying the filesystem (container) name.
    #' @param scope A character string specifying the OAuth2 scope. Defaults to
    #'   `default_azure_scope("azure_storage")`.
    #' @param endpoint_suffix A character string specifying the Azure
    #'   Storage DFS endpoint suffix. Defaults to
    #'   [default_storage_endpoint()].
    #' @param provider An optional credential provider object that inherits from
    #'   `Credential` or `DefaultCredential`. If provided, `chain` is ignored.
    #' @param chain A [credential_chain] instance for authentication. If NULL,
    #'   a default credential chain will be created using [DefaultCredential].
    #' @param tenant_id A character string specifying the Azure tenant ID. Passed to
    #'   [DefaultCredential] when `chain` is `NULL`.
    #' @param ... Additional arguments passed to the parent [api_client] constructor.
    #'
    #' @return A new `api_storage_client` object
    initialize = function(
      storageaccount,
      filesystem,
      scope = default_azure_scope("azure_storage"),
      endpoint_suffix = default_storage_endpoint(),
      provider = NULL,
      chain = NULL,
      tenant_id = NULL,
      ...
    ) {
      if (missing(storageaccount) || is.null(storageaccount)) {
        cli::cli_abort("{.arg storageaccount} must not be {.val NULL}.")
      }
      if (missing(filesystem) || is.null(filesystem)) {
        cli::cli_abort("{.arg filesystem} must not be {.val NULL}.")
      }
      if (!is.character(filesystem) || length(filesystem) != 1L) {
        cli::cli_abort("{.arg filesystem} must be a single character string.")
      }
      if (
        !is.character(endpoint_suffix) ||
          length(endpoint_suffix) != 1L ||
          !nzchar(endpoint_suffix)
      ) {
        cli::cli_abort(
          "{.arg endpoint_suffix} must be a non-empty character string."
        )
      }

      host_url <- storage_host_url(
        storageaccount = storageaccount,
        endpoint_suffix = endpoint_suffix
      )

      if (length(scope) > 1) {
        scope <- paste(scope, collapse = " ")
      }

      # Create credential provider
      if (is.null(provider)) {
        provider <- DefaultCredential$new(
          scope = scope,
          chain = chain,
          tenant_id = tenant_id
        )
      } else if (!is_credential(provider)) {
        cli::cli_abort(
          "Argument {.arg provider} must inherit from {.cls Credential},
          {.cls DefaultCredential}, or {.cls CachedTokenCredential}."
        )
      }

      self$.filesystem <- filesystem

      super$initialize(host_url = host_url, provider = provider, ...)

      lockBinding(".filesystem", self)
    },

    #' @description
    #' Download a file from the filesystem
    #'
    #' @param path A character string specifying the file path within the filesystem.
    #' @param dest A character string specifying the local destination path.
    #'   Defaults to a temporary file via [tempfile()].
    #'
    #' @return The local path the file was written to (invisibly).
    download_file = function(path, dest = NULL) {
      if (missing(path) || is.null(path) || !nzchar(path)) {
        cli::cli_abort("{.arg path} must be a non-empty character string.")
      }
      if (is.null(dest)) {
        dest <- tempfile()
      }

      resp <- self$.fetch(
        path = paste0(self$.filesystem, "/", path),
        method = "get",
        content = "response"
      )

      writeBin(httr2::resp_body_raw(resp), dest)

      invisible(dest)
    },

    #' @description
    #' Get the access control list (ACL) for a file or directory
    #'
    #' @param dataset A character string specifying the file or directory path within
    #'   the filesystem.
    #' @param upn A logical value. If `TRUE`, user principal names (UPN) are
    #'   returned in the `x-ms-owner`, `x-ms-group`, and `x-ms-acl` response
    #'   headers instead of object IDs. Defaults to `FALSE`.
    #'
    #' @return A data.frame with columns `group_id` and `permission`, one row per
    #'   named group entry in the `x-ms-acl` response header.
    get_access_control = function(dataset, upn = FALSE) {
      if (missing(dataset) || is.null(dataset) || !nzchar(dataset)) {
        cli::cli_abort("{.arg dataset} must be a non-empty character string.")
      }

      resp <- self$.fetch(
        path = paste0(self$.filesystem, "/{dataset}"),
        dataset = dataset,
        query = list(
          action = "getAccessControl",
          upn = tolower(as.character(upn))
        ),
        headers = list(`x-ms-version` = "2023-11-03"),
        method = "head",
        content = "headers"
      )

      acl_raw <- resp[["x-ms-acl"]]
      entries <- strsplit(acl_raw, ",")[[1]]
      group_entries <- entries[grepl("^group:[^:]+:", entries)]
      parts <- strsplit(group_entries, ":")

      data.frame(
        group_id = vapply(parts, `[[`, character(1L), 2L),
        permission = vapply(parts, `[[`, character(1L), 3L),
        stringsAsFactors = FALSE
      )
    },

    #' @description
    #' List files and directories in a path
    #'
    #' @param path A character string specifying the directory path to list.
    #'   Use empty string or NULL for the root directory. Defaults to `""`.
    #' @param recursive A logical value indicating whether to list files recursively.
    #'   Defaults to `FALSE`.
    #' @param ... Additional query parameters to pass to the API.
    #'
    #' @return A data.frame (or data.table if available) with one row per file or
    #'   directory. Columns include `name`, `contentLength`, `lastModified`, etc.
    #'   All pages are fetched transparently; the result is the complete listing.
    list_files = function(path = "", recursive = FALSE, ...) {
      if (is.null(path)) {
        path <- ""
      }

      query_params <- list(
        resource = "filesystem",
        recursive = tolower(as.character(recursive)),
        ...
      )

      if (nzchar(path)) {
        query_params$directory <- path
      }

      req <- self$.fetch(
        path = self$.filesystem,
        query = query_params,
        method = "get",
        content = "request"
      )
      req <- self$.credentials(req)

      resps <- httr2::req_perform_iterative(
        req,
        next_req = httr2::iterate_with_cursor(
          "continuation",
          \(resp) httr2::resp_header(resp, "x-ms-continuation")
        ),
        max_reqs = Inf
      )

      pages <- httr2::resps_data(resps, \(resp) {
        body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
        body$paths
      })

      if (is.null(pages) || length(pages) == 0L) {
        cli::cli_inform("No files found in path: {.path {path}}")
        return(data.frame())
      }

      self$.response_handler(as.data.frame(pages))
    }
  )
)

storage_host_url <- function(storageaccount, endpoint_suffix) {
  endpoint_suffix <- sub("/+$", "", endpoint_suffix)
  endpoint_suffix <- sub("^https?://", "", endpoint_suffix)
  endpoint_suffix <- sub("^\\.+", "", endpoint_suffix)
  if (!nzchar(endpoint_suffix)) {
    cli::cli_abort(
      "{.arg endpoint_suffix} must be a non-empty character string."
    )
  }

  rlang::englue("https://{storageaccount}.{endpoint_suffix}")
}

#' Create an Azure Storage Client
#'
#' @description
#' A convenience wrapper around [api_storage_client] that creates a configured
#' client for Azure Data Lake Storage Gen2 (ADLS Gen2) REST API operations.
#'
#' @param storageaccount A character string specifying the Azure Storage account name.
#' @param filesystem A character string specifying the filesystem (container) name.
#' @param endpoint_suffix A character string specifying the Azure
#'   Storage DFS endpoint suffix. Defaults to
#'   [default_storage_endpoint()].
#' @param scope A character string specifying the OAuth2 scope. Defaults to
#'   `default_azure_scope("azure_storage")`.
#' @param provider An optional credential provider object that inherits from
#'   `Credential` or `DefaultCredential`. If provided, `chain` is ignored.
#' @param chain A [credential_chain] instance for authentication. Defaults to
#'   [default_credential_chain()].
#' @param tenant_id A character string specifying the Azure tenant ID. Defaults to
#'   [default_azure_tenant_id()], which reads `AZURE_TENANT_ID` from the environment.
#' @param ... Additional arguments passed to the [api_storage_client] constructor.
#'
#' @return An [api_storage_client] object.
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a storage client with default credentials
#' storage <- azr_storage_client(
#'   storageaccount = "mystorageaccount",
#'   filesystem = "mycontainer"
#' )
#'
#' # Create a storage client with a specific tenant
#' storage <- azr_storage_client(
#'   storageaccount = "mystorageaccount",
#'   filesystem = "mycontainer",
#'   tenant_id = "00000000-0000-0000-0000-000000000000"
#' )
#' }
azr_storage_client <- function(
  storageaccount,
  filesystem,
  endpoint_suffix = default_storage_endpoint(),
  scope = default_azure_scope("azure_storage"),
  provider = NULL,
  chain = default_credential_chain(),
  tenant_id = default_azure_tenant_id(),
  ...
) {
  api_storage_client$new(
    storageaccount = storageaccount,
    filesystem = filesystem,
    endpoint_suffix = endpoint_suffix,
    scope = scope,
    provider = provider,
    chain = chain,
    tenant_id = tenant_id,
    ...
  )
}
