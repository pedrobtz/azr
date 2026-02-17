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
    #' @param ... Additional arguments passed to the parent [api_client] constructor.
    #'
    #' @return A new `api_storage_client` object
    initialize = function(
      storageaccount,
      filesystem,
      scopes = ".default",
      chain = NULL,
      ...
    ) {
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
      host_url <- rlang::englue(
        "https://{{storageaccount}}.dfs.core.windows.net"
      )
      if (!is.character(filesystem) || length(filesystem) != 1L) {
        cli::cli_abort("{.arg filesystem} must be a single character string.")
      }

      # Construct the Azure Storage Data Lake Gen2 URL
      host_url <- rlang::englue("https://{{storageaccount}}.dfs.core.windows.net")

      # Construct the full scope URL for Azure Storage
      if (length(scopes) > 1) {
        scopes <- paste(scopes, collapse = " ")
      }
      scope <- paste0("https://storage.azure.com/", scopes)

      # Create credential provider
      provider <- DefaultCredential$new(scope = scope, chain = chain)

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
    #' List files and directories in a path
    #'
    #' @param path A character string specifying the directory path to list.
    #'   Use empty string or NULL for the root directory. Defaults to `""`.
    #' @param recursive A logical value indicating whether to list files recursively.
    #'   Ignored when `max_depth` is set. Defaults to `FALSE`.
    #' @param max_depth An integer specifying the maximum directory depth to traverse.
    #'   `1` returns only immediate children (equivalent to `recursive = FALSE`).
    #'   Each additional level issues separate API calls per subdirectory rather than
      if (is.null(path)) {
        path <- ""
      }
    #' @param ... Additional query parameters to pass to the API.
    #'
    #' @return A data.frame (or data.table if available) containing file and directory
        recursive = if (is.null(max_depth)) {
          tolower(as.character(recursive))
        } else {
          "false"
        },
    list_files = function(path = "", recursive = FALSE, max_depth = NULL, ...) {
      if (is.null(path)) path <- ""

      if (nzchar(path)) {
        query_params$directory <- path
      }
        resource = "filesystem",
        recursive = if (is.null(max_depth)) tolower(as.character(recursive)) else "false",
        ...
      )

      if (nzchar(path)) query_params$directory <- path

      response <- self$.fetch(
        path = self$.filesystem,
        query = query_params,
        method = "get"
      )

      if (is.null(response$paths) || !is.data.frame(response$paths)) {
        cli::cli_inform("No files found in path: {.path {path}}")
        return(data.frame())
      }

      result <- response$paths

      if (!is.null(max_depth) && max_depth > 1L) {
        dirs <- result$name[result$isDirectory %in% c(TRUE, "true")]
        deeper <- lapply(dirs, function(dir) {
          self$list_files(path = dir, max_depth = max_depth - 1L, ...)
        })
        deeper <- Filter(function(x) nrow(x) > 0L, deeper)
        if (length(deeper) > 0L) {
          result <- do.call(rbind, c(list(result), deeper))
        }
      }

      result
    }
  )
)
