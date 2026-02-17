#' Azure Storage API Class
#'
#' @description
#' An R6 class that extends [api_client] to provide specialized methods
#' for Azure Data Lake Storage Gen2 (ADLS Gen2) REST API operations.
#'
#' @details
#' The base URL is constructed as:
#' `https://{storageaccount}.dfs.core.windows.net`
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
    #' @param scopes A character string specifying the OAuth2 scope suffix. Defaults to
    #'   `".default"`, which requests all permissions the app has been granted.
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
      scopes = ".default",
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

      # Construct the Azure Storage Data Lake Gen2 URL
      host_url <- rlang::englue(
        "https://{storageaccount}.dfs.core.windows.net"
      )

      # Construct the full scope URL for Azure Storage
      if (length(scopes) > 1) {
        scopes <- paste(scopes, collapse = " ")
      }
      scope <- paste0("https://storage.azure.com/", scopes)

      # Create credential provider
      provider <- DefaultCredential$new(
        scope = scope,
        chain = chain,
        tenant_id = tenant_id
      )

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
    #' @return A data.frame (or data.table if available) containing file and directory
    #'   information with columns such as name, contentLength, lastModified, etc.
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

      response <- self$.fetch(
        path = self$.filesystem,
        query = query_params,
        method = "get"
      )

      if (!is.null(response$paths) && is.data.frame(response$paths)) {
        return(response$paths)
      } else {
        cli::cli_inform("No files found in path: {.path {path}}")
        return(data.frame())
      }
    }
  )
)

#' Create an Azure Storage Client
#'
#' @description
#' A convenience wrapper around [api_storage_client] that creates a configured
#' client for Azure Data Lake Storage Gen2 (ADLS Gen2) REST API operations.
#'
#' @param storageaccount A character string specifying the Azure Storage account name.
#' @param filesystem A character string specifying the filesystem (container) name.
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
  chain = default_credential_chain(),
  tenant_id = default_azure_tenant_id(),
  ...
) {
  api_storage_client$new(
    storageaccount = storageaccount,
    filesystem = filesystem,
    chain = chain,
    tenant_id = tenant_id,
    ...
  )
}
