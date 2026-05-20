#' Parse an Azure Storage path
#'
#' @description
#' Splits an Azure Storage URL or Hadoop filesystem path into its constituent
#' parts. Supports all common Azure Storage path formats:
#'
#' \describe{
#'   \item{`abfss://` / `abfs://`}{Azure Data Lake Storage Gen2 (DFS endpoint),
#'     used by Spark / Hadoop.}
#'   \item{`wasbs://` / `wasb://`}{Legacy Azure Blob filesystem scheme, used by
#'     older Spark / Hadoop integrations.}
#'   \item{`https://` / `http://`}{Standard Azure Blob or DFS REST endpoint,
#'     optionally with a SAS token query string.}
#'   \item{`az://` / `azure://`}{Non-standard aliases used by some Python tools
#'     (e.g. `adlfs`); parsed using the same `container@account.host/path`
#'     shape as `abfs://`.}
#' }
#'
#' The `format` field is inferred from the path on a best-effort basis:
#' `"delta"` when the path contains `_delta_log`; a file extension name
#' (`"parquet"`, `"csv"`, `"json"`, `"avro"`, `"orc"`, `"text"`) when the
#' last path segment has a recognised extension; `"folder"` when there is no
#' extension; and `NA` for unrecognised extensions.
#'
#' @param path A character string containing the Azure Storage path to parse.
#'
#' @return An `azure_storage_path` object (a named list) with the fields:
#' \describe{
#'   \item{`scheme`}{URL scheme, e.g. `"abfss"`, `"wasbs"`, `"https"`.}
#'   \item{`storage_account`}{Storage account name.}
#'   \item{`endpoint`}{Storage endpoint type: `"dfs"` or `"blob"`.}
#'   \item{`endpoint_suffix`}{Host suffix after the endpoint label, e.g.
#'     `"core.windows.net"` (Azure public), `"core.usgovcloudapi.net"`
#'     (US Government), `"core.chinacloudapi.cn"` (China), or
#'     `"storage.azure.net"` (DNS-zone endpoints). Use this to distinguish
#'     sovereign clouds from the public cloud.}
#'   \item{`container`}{Container name. Called "filesystem" in ADLS Gen2 /
#'     ABFS contexts; both refer to the same underlying object.}
#'   \item{`path`}{Path within the container, without a leading `/`. Empty
#'     string if the URL points to the container root.}
#'   \item{`format`}{Inferred dataset or file format (see above).}
#'   \item{`query`}{Named list of query parameters (e.g. a parsed SAS token),
#'     or `NULL` if none.}
#'   \item{`original`}{The original input string.}
#' }
#'
#' @export
#' @examples
#' parse_storage_path(
#'   "abfss://mycontainer@myaccount.dfs.core.windows.net/data/sales/2024"
#' )
#'
#' parse_storage_path(
#'   "https://myaccount.blob.core.windows.net/mycontainer/data/events.parquet"
#' )
#'
#' parse_storage_path(
#'   "wasbs://mycontainer@myaccount.blob.core.windows.net/data/delta_table"
#' )
parse_storage_path <- function(path) {
  if (!rlang::is_string(path) || !nzchar(path)) {
    cli::cli_abort("{.arg path} must be a non-empty string.")
  }

  parsed <- httr2::url_parse(path)

  scheme <- parsed$scheme %||% NA_character_
  valid_schemes <- c(
    "abfss",
    "abfs",
    "wasbs",
    "wasb",
    "https",
    "http",
    "az",
    "azure"
  )

  if (is.na(scheme) || !scheme %in% valid_schemes) {
    cli::cli_abort(c(
      "Unrecognised scheme {.val {scheme}} in {.val {path}}.",
      "i" = "Supported schemes: {.val {valid_schemes}}."
    ))
  }

  host <- parsed$hostname %||% NA_character_
  host_parts <- strsplit(host, ".", fixed = TRUE)[[1]]

  if (length(host_parts) < 2L) {
    cli::cli_abort(c(
      "Invalid storage hostname {.val {host}} in {.val {path}}.",
      "i" = "Expected format: {.val <account>.dfs.core.windows.net} or
      {.val <container>@<account>.dfs.core.windows.net}."
    ))
  }

  storage_account <- host_parts[[1]]

  # Endpoint is normally label 2 (account.dfs.core.windows.net), but DNS-zone
  # endpoints insert a zNN label first (account.z42.blob.storage.azure.net).
  endpoint_index <- if (
    length(host_parts) >= 2L &&
      grepl("^z[0-9]+$", host_parts[[2L]])
  ) {
    3L
  } else {
    2L
  }
  endpoint <- if (length(host_parts) >= endpoint_index) {
    host_parts[[endpoint_index]]
  } else {
    NA_character_
  }
  endpoint_suffix <- if (length(host_parts) > endpoint_index) {
    paste(host_parts[-seq_len(endpoint_index)], collapse = ".")
  } else {
    NA_character_
  }

  if (!endpoint %in% c("dfs", "blob")) {
    cli::cli_warn(
      "Unexpected endpoint {.val {endpoint}} in hostname {.val {host}}; expected {.val dfs} or {.val blob}."
    )
  }

  if (scheme %in% c("abfss", "abfs", "wasbs", "wasb", "az", "azure")) {
    container <- parsed$username %||% NA_character_
    inner_path <- sub("^/", "", parsed$path %||% "")
  } else {
    path_segments <- strsplit(
      sub("^/", "", parsed$path %||% ""),
      "/",
      fixed = TRUE
    )[[1]]
    path_segments <- path_segments[nzchar(path_segments)]
    container <- if (length(path_segments) >= 1L) {
      path_segments[[1L]]
    } else {
      NA_character_
    }
    inner_path <- paste(path_segments[-1L], collapse = "/")
  }

  structure(
    list(
      scheme = scheme,
      storage_account = storage_account,
      endpoint = endpoint,
      endpoint_suffix = endpoint_suffix,
      container = container,
      path = inner_path,
      format = storage_path_format(inner_path, parsed$path %||% ""),
      query = parsed$query,
      original = path
    ),
    class = "azure_storage_path"
  )
}


#' @export
print.azure_storage_path <- function(x, ...) {
  cli::cli_text(cli::style_bold("<azure_storage_path>"))
  cli::cli_dl(c(
    scheme = x$scheme,
    storage_account = x$storage_account,
    endpoint = x$endpoint,
    endpoint_suffix = x$endpoint_suffix %||% "(none)",
    container = x$container %||% "(none)",
    path = if (nzchar(x$path)) x$path else "(container root)",
    format = x$format %||% "(unknown)"
  ))
  if (!is.null(x$query)) {
    cli::cli_text("query:")
    cli::cli_dl(unlist(lapply(redact_sas(x$query), as.character)))
  }
  invisible(x)
}

# Keys that carry SAS credentials or identity material; redacted on print.
sas_sensitive_keys <- c(
  "sig",
  "skoid",
  "sktid",
  "skt",
  "ske",
  "sks",
  "skv",
  "signedoid",
  "signedtid"
)

redact_sas <- function(query) {
  hits <- intersect(names(query), sas_sensitive_keys)
  query[hits] <- "<redacted>"
  query
}


storage_path_format <- function(inner_path, raw_path) {
  if (grepl("_delta_log", inner_path, fixed = TRUE)) {
    return("delta")
  }

  # Trailing slash → unambiguous folder
  if (endsWith(raw_path, "/")) {
    return("folder")
  }

  ext <- tolower(tools::file_ext(inner_path))

  if (!nzchar(ext)) {
    return("folder")
  }

  switch(
    ext,
    parquet = "parquet",
    csv = "csv",
    tsv = "tsv",
    json = ,
    jsonl = ,
    ndjson = "json",
    avro = "avro",
    orc = "orc",
    txt = ,
    text = "text",
    NA_character_
  )
}
