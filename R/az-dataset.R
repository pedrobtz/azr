#' Azure Storage dataset
#'
#' @description
#' An S7 class representing an Azure Storage dataset bound to one or more
#' storage accounts keyed by environment tier (e.g. `"prod"`, `"preprod"`).
#'
#' @param name Dataset name. Must match `^[a-z][a-z0-9_]*$`.
#' @param scheme Hadoop filesystem scheme: `"abfss"` or `"wasbs"`.
#' @param container Container (filesystem) name.
#' @param storage Non-empty named list mapping tier name to storage account.
#' @param path Path within the container, without leading or trailing `/`.
#' @param format Dataset format: `"delta"`, `"parquet"`, `"csv"`, or `"json"`.
#' @param endpoint_suffix Storage endpoint suffix. Defaults to
#'   `"core.windows.net"`.
#'
#' @return An `az_dataset` S7 object.
#' @export
az_dataset <- S7::new_class(
  "az_dataset",
  properties = list(
    name = S7::class_character,
    scheme = S7::class_character,
    container = S7::class_character,
    storage = S7::class_list,
    path = S7::class_character,
    format = S7::class_character,
    endpoint_suffix = S7::new_property(
      S7::class_character,
      default = "core.windows.net"
    )
  ),
  validator = function(self) {
    if (!is_scalar_string(self@name)) {
      return("name must be a non-empty character scalar")
    }
    if (!grepl("^[a-z][a-z0-9_]*$", self@name)) {
      return("name must match ^[a-z][a-z0-9_]*$ for stable catalog lookups")
    }
    if (!self@scheme %in% c("abfss", "wasbs")) {
      return("scheme must be one of: abfss, wasbs")
    }
    if (!is_scalar_string(self@container)) {
      return("container must be a non-empty character scalar")
    }
    if (!grepl("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", self@container)) {
      return(
        "container must be 3-63 chars, lowercase alphanumeric or '-', and start/end alphanumeric"
      )
    }
    if (!is_scalar_string(self@path)) {
      return("path must be a non-empty character scalar")
    }
    if (grepl("^/|/$", self@path)) {
      return("path must not start or end with '/'")
    }
    if (grepl("//", self@path, fixed = TRUE)) {
      return("path must not contain empty segments ('//')")
    }
    if (grepl("\\?", self@path)) {
      return("path must not contain query string components")
    }
    if (!self@format %in% c("delta", "parquet", "csv", "json")) {
      return("format must be one of: delta, parquet, csv, json")
    }
    if (length(self@storage) == 0L || is.null(names(self@storage))) {
      return("storage must be a non-empty named list")
    }
    if (any(!nzchar(names(self@storage)))) {
      return("storage names must be non-empty")
    }
    if (!all(vapply(self@storage, is_scalar_string, logical(1L)))) {
      return("storage values must be non-empty character scalars")
    }
    if (!is_scalar_string(self@endpoint_suffix)) {
      return("endpoint_suffix must be a non-empty character scalar")
    }
    NULL
  }
)


#' Azure Storage dataset catalog
#'
#' @description
#' An S7 class holding an ordered collection of [az_dataset] objects with
#' unique `name`s.
#'
#' @param datasets A list of [az_dataset] objects.
#'
#' @return An `az_data_catalog` S7 object.
#' @export
az_data_catalog <- S7::new_class(
  "az_data_catalog",
  properties = list(
    datasets = S7::class_list
  ),
  validator = function(self) {
    if (
      !all(vapply(
        self@datasets,
        function(d) S7::S7_inherits(d, az_dataset),
        logical(1L)
      ))
    ) {
      return("datasets must be a list of az_dataset objects")
    }
    names <- vapply(self@datasets, function(d) d@name, character(1L))
    if (anyDuplicated(names) > 0L) {
      dupes <- unique(names[duplicated(names)])
      return(paste0(
        "dataset names must be unique. Duplicates: ",
        paste(dupes, collapse = ", ")
      ))
    }
    NULL
  }
)


#' Create an `az_dataset` from a full Azure Storage URI
#'
#' @description
#' Parses an Azure Storage URI using [parse_storage_path()] and constructs an
#' [az_dataset]. The parsed storage account is bound to `tier` in `storage`.
#'
#' @param uri Full Azure Storage URI, such as
#'   `abfss://raw@account.dfs.core.windows.net/path` or
#'   `https://account.dfs.core.windows.net/raw/path`.
#' @param name Dataset name.
#' @param format Dataset format. If `NULL`, inferred from the URI.
#' @param tier Environment tier for the storage account parsed from `uri`.
#'   Defaults to `"prod"`.
#' @param storage Optional named list mapping additional tiers to storage
#'   accounts. The account from `uri` is bound to `tier` unless that key is
#'   already present.
#'
#' @return An [az_dataset] object.
#' @export
az_dataset_from_uri <- function(
  uri,
  name,
  format = NULL,
  tier = "prod",
  storage = NULL
) {
  parsed <- parse_storage_path(uri)
  scheme <- normalise_scheme(parsed$scheme, parsed$endpoint)

  storage <- if (is.null(storage)) {
    stats::setNames(list(parsed$storage_account), tier)
  } else {
    storage <- as.list(storage)
    storage[[tier]] <- storage[[tier]] %||% parsed$storage_account
    storage
  }

  az_dataset(
    name = name,
    scheme = scheme,
    container = parsed$container,
    storage = storage,
    path = parsed$path,
    format = format %||% parsed$format,
    endpoint_suffix = parsed$endpoint_suffix %||% "core.windows.net"
  )
}


#' Load a dataset catalog from JSON
#'
#' @description
#' Reads a JSON file describing a collection of datasets and returns an
#' [az_data_catalog].
#'
#' The expected JSON shape:
#' \preformatted{
#' {
#'   "datasets": [
#'     {
#'       "name": "sales_orders",
#'       "scheme": "abfss",
#'       "container": "raw",
#'       "storage": { "prod": "stprod001", "preprod": "stpreprod001" },
#'       "path": "sales/orders",
#'       "format": "delta"
#'     }
#'   ]
#' }
#' }
#'
#' @param json_file Path to a JSON file.
#'
#' @return An [az_data_catalog] object.
#' @export
load_dataset_catalog <- function(json_file) {
  raw <- jsonlite::fromJSON(json_file, simplifyVector = FALSE)
  if (!is.list(raw$datasets) || length(raw$datasets) == 0L) {
    cli::cli_abort(
      "JSON must contain a non-empty top-level {.field datasets} array."
    )
  }

  required <- c("name", "scheme", "container", "storage", "path", "format")
  datasets <- lapply(raw$datasets, function(x) {
    missing_fields <- setdiff(required, names(x))
    if (length(missing_fields) > 0L) {
      cli::cli_abort(c(
        "Dataset entry is missing required fields:",
        "*" = "{.field {missing_fields}}"
      ))
    }

    az_dataset(
      name = x$name,
      scheme = x$scheme,
      container = x$container,
      storage = x$storage,
      path = x$path,
      format = x$format,
      endpoint_suffix = x$endpoint_suffix %||% "core.windows.net"
    )
  })

  az_data_catalog(datasets = datasets)
}


#' Build a URI for an `az_dataset`
#'
#' @param x An [az_dataset] object.
#' @param tier Environment tier name (a key in `x@storage`).
#' @param uri_type URI type: `"https"` or `"hadoop"` (the Hadoop ABFS URI
#'   form `scheme://container@account.dfs.../path`, used by Spark, Flink,
#'   Trino, and any `hadoop-azure` consumer).
#'
#' @return A character scalar URI.
#' @export
dataset_uri <- S7::new_generic("dataset_uri", "x")
S7::method(dataset_uri, az_dataset) <- function(
  x,
  tier,
  uri_type = c("hadoop", "https")
) {
  uri_type <- rlang::arg_match(uri_type)
  if (!tier %in% names(x@storage)) {
    cli::cli_abort(c(
      "Unknown tier {.val {tier}}.",
      "i" = "Available tiers: {.val {names(x@storage)}}."
    ))
  }
  compute_dataset_uri(
    scheme = x@scheme,
    account = x@storage[[tier]],
    container = x@container,
    path = x@path,
    endpoint_suffix = x@endpoint_suffix,
    uri_type = uri_type
  )
}


#' Look up a dataset URI by name in a catalog
#'
#' @param catalog An [az_data_catalog] object.
#' @param name Dataset name to look up.
#' @param tier Environment tier name.
#' @param uri_type URI type: `"https"` or `"hadoop"` (the Hadoop ABFS URI
#'   form `scheme://container@account.dfs.../path`, used by Spark, Flink,
#'   Trino, and any `hadoop-azure` consumer).
#'
#' @return A character scalar URI.
#' @export
lookup_dataset_uri <- function(
  catalog,
  name,
  tier,
  uri_type = c("hadoop", "https")
) {
  if (!S7::S7_inherits(catalog, az_data_catalog)) {
    cli::cli_abort("{.arg catalog} must be an {.cls az_data_catalog} object.")
  }
  idx <- which(vapply(
    catalog@datasets,
    function(d) identical(d@name, name),
    logical(1L)
  ))
  if (length(idx) != 1L) {
    cli::cli_abort("Dataset {.val {name}} was not found in the catalog.")
  }
  dataset_uri(catalog@datasets[[idx]], tier = tier, uri_type = uri_type)
}


#' Build URIs for every dataset in a catalog
#'
#' @param catalog An [az_data_catalog] object.
#' @param tier Environment tier name.
#' @param uri_type URI type: `"https"` or `"hadoop"` (the Hadoop ABFS URI
#'   form `scheme://container@account.dfs.../path`, used by Spark, Flink,
#'   Trino, and any `hadoop-azure` consumer).
#'
#' @return A named character vector of URIs keyed by dataset name.
#' @export
catalog_dataset_uris <- function(
  catalog,
  tier,
  uri_type = c("hadoop", "https")
) {
  if (!S7::S7_inherits(catalog, az_data_catalog)) {
    cli::cli_abort("{.arg catalog} must be an {.cls az_data_catalog} object.")
  }
  out <- vapply(
    catalog@datasets,
    function(d) dataset_uri(d, tier = tier, uri_type = uri_type),
    character(1L)
  )
  names(out) <- vapply(catalog@datasets, function(d) d@name, character(1L))
  out
}


# S3 methods registered via S7 (S7 namespaces class to "pkg::class") ------

# nolint next: object_name_linter.
S7::method(as.list, az_dataset) <- function(x, ...) {
  list(
    name = x@name,
    scheme = x@scheme,
    container = x@container,
    storage = x@storage,
    path = x@path,
    format = x@format,
    endpoint_suffix = x@endpoint_suffix
  )
}

# nolint next: object_name_linter.
S7::method(as.list, az_data_catalog) <- function(x, ...) {
  list(datasets = lapply(x@datasets, as.list))
}

S7::method(print, az_dataset) <- function(x, ...) {
  cli::cli_text(cli::style_bold("<az_dataset:{x@name}>"))
  cli::cli_dl(c(
    scheme = x@scheme,
    container = x@container,
    path = x@path,
    format = x@format,
    storage = paste0(
      names(x@storage),
      "=",
      unlist(x@storage),
      collapse = ", "
    )
  ))
  invisible(x)
}

S7::method(print, az_data_catalog) <- function(x, ...) {
  n <- length(x@datasets)
  cli::cli_text(cli::style_bold("<az_data_catalog>"), " ({n} dataset{?s})")
  for (d in x@datasets) {
    cli::cli_text("  ", d@name)
  }
  invisible(x)
}


# Helpers ----------------------------------------------------------------

compute_dataset_uri <- function(
  scheme,
  account,
  container,
  path,
  endpoint_suffix,
  uri_type
) {
  endpoint <- if (scheme == "abfss") "dfs" else "blob"
  host <- sprintf("%s.%s.%s", account, endpoint, endpoint_suffix)
  switch(
    uri_type,
    https = sprintf("https://%s/%s/%s", host, container, path),
    hadoop = sprintf("%s://%s@%s/%s", scheme, container, host, path)
  )
}

normalise_scheme <- function(scheme, endpoint) {
  if (scheme %in% c("https", "http")) {
    if (identical(endpoint, "dfs")) {
      return("abfss")
    }
    if (identical(endpoint, "blob")) {
      return("wasbs")
    }
    cli::cli_abort("Cannot infer scheme from endpoint {.val {endpoint}}.")
  }
  if (scheme %in% c("abfs", "wasb")) {
    return(paste0(scheme, "s"))
  }
  if (scheme %in% c("abfss", "wasbs")) {
    return(scheme)
  }
  cli::cli_abort("Unsupported scheme {.val {scheme}}.")
}

is_scalar_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}
