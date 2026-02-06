#' Create an Azure Storage API Client
#'
#' @description
#' Creates a configured client for Azure Data Lake Storage Gen2 (ADLS Gen2) REST API.
#' This function returns an [api_storage_client] object that provides methods for
#' interacting with files and directories in Azure Storage.
#'
#' @details
#' The function creates an Azure Storage client that uses the Data Lake Storage Gen2
#' REST API endpoints. The base URL is constructed as:
#' `https://{storageaccount}.dfs.core.windows.net`
#'
#' The client is configured with:
#' - Azure authentication using credential provider
#' - Access to a specific filesystem (container)
#' - Methods for listing files and directories
#'
#' @param storageaccount A character string specifying the Azure Storage account name.
#' @param filesystem A character string specifying the filesystem (container) name.
#' @param scopes A character string specifying the OAuth2 scope suffix. Defaults to
#'   `".default"`, which requests all permissions the app has been granted.
#' @param chain A [credential_chain] instance for authentication. If NULL,
#'   a default credential chain will be created using [DefaultCredential].
#' @param ... Additional arguments passed to the [api_storage_client] constructor.
#'
#' @return An [api_storage_client] object configured for Azure Storage with methods
#'   to interact with files and directories.
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a storage client
#' storage <- azr_storage_client(
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
azr_storage_client <- function(
  storageaccount,
  filesystem,
  scopes = ".default",
  chain = NULL,
  ...
) {
  if (missing(storageaccount) || is.null(storageaccount)) {
    cli::cli_abort("{.arg storageaccount} must not be {.val NULL}.")
  }
  if (missing(filesystem) || is.null(filesystem)) {
    cli::cli_abort("{.arg filesystem} must not be {.val NULL}.")
  }

  # Construct the Azure Storage Data Lake Gen2 URL
  storage_url <- glue::glue("https://{storageaccount}.dfs.core.windows.net")

  # Construct the full scope URL for Azure Storage
  if (length(scopes) > 1) {
    scopes <- paste(scopes, collapse = " ")
  }
  scope <- paste0("https://storage.azure.com/", scopes)

  # Create credential provider
  provider <- DefaultCredential$new(
    scope = scope,
    chain = chain
  )

  # Create the storage API client
  client <- api_storage_client$new(
    host_url = storage_url,
    filesystem = filesystem,
    provider = provider,
    ...
  )

  return(client)
}


#' Azure Storage API Class
#'
#' @description
#' An R6 class that extends [api_client] to provide specialized methods
#' for Azure Data Lake Storage Gen2 (ADLS Gen2) REST API operations.
#'
#' @details
#' This class extends the base [api_client] with Azure Storage-specific functionality:
#' - Automatic filesystem (container) path handling
#' - Methods for listing files and directories
#' - Support for recursive directory listing
#'
#' The class uses the Azure Data Lake Storage Gen2 REST API which provides
#' hierarchical namespace capabilities and file system semantics.
#'
#' @keywords internal
api_storage_client <- R6::R6Class(
  classname = "api_storage_client",
  inherit = api_client,
  public = list(
    #' @field .filesystem The filesystem (container) name
    .filesystem = NULL,

    #' @description
    #' Create a new Azure Storage API client instance
    #'
    #' @param host_url A character string specifying the base URL for the Azure Storage account
    #'   (e.g., `"https://mystorageaccount.dfs.core.windows.net"`).
    #' @param filesystem A character string specifying the filesystem (container) name.
    #' @param provider An R6 credential provider object for authentication.
    #' @param ... Additional arguments passed to the parent [api_client] constructor.
    #'
    #' @return A new `api_storage_client` object
    initialize = function(host_url, filesystem, provider = NULL, ...) {
      # Validate filesystem parameter
      if (is.null(filesystem)) {
        cli::cli_abort("{.arg filesystem} must not be {.val NULL}.")
      }
      if (!is.character(filesystem) || length(filesystem) != 1L) {
        cli::cli_abort(
          "{.arg filesystem} must be a single character string."
        )
      }

      # Store the filesystem
      self$.filesystem <- filesystem

      # Call parent constructor
      super$initialize(
        host_url = host_url,
        provider = provider,
        ...
      )

      # Lock the filesystem field
      lockBinding(".filesystem", self)
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
      # Normalize path
      if (is.null(path)) {
        path <- ""
      }

      # Build query parameters for the list operation
      query_params <- list(
        resource = "filesystem",
        recursive = tolower(as.character(recursive)),
        ...
      )

      # Add directory parameter if path is not empty
      if (nzchar(path)) {
        query_params$directory <- path
      }

      # Build the API path
      api_path <- self$.filesystem

      # Make the request
      response <- self$.fetch(
        path = api_path,
        req_data = query_params,
        req_method = "get"
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
