#' Azure Storage dataset
#'
#' @description
#' An S7 class representing an Azure Storage dataset bound to one or more
#' storage accounts keyed by environment tier (e.g. `"prod"`, `"preprod"`).
#'
#' @details
#' Only the storage account varies by tier: `container`, `path`,
#' `endpoint_suffix`, and `scheme` are shared across all tiers in `storage`.
#' If an environment also needs a different container, path, or sovereign
#' cloud, model it as a separate [az_dataset].
#'
#' `path` must be non-empty, so a dataset cannot point at a container root.
#'
#' @param name Dataset name. Must match `^[a-z][a-z0-9_]*$`.
#' @param scheme Hadoop filesystem scheme: `"abfss"` or `"wasbs"`.
#' @param container Container (filesystem) name.
#' @param storage Non-empty named list mapping tier name to storage account.
#' @param path Path within the container, without leading or trailing `/`.
#' @param format Dataset format: `"delta"`, `"parquet"`, `"csv"`, `"tsv"`,
#'   `"json"`, `"avro"`, `"orc"`, or `"text"`.
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
    if (!self@format %in% dataset_formats) {
      return(paste0(
        "format must be one of: ",
        paste(dataset_formats, collapse = ", ")
      ))
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

# Recognised dataset formats. Purely descriptive metadata: compute_dataset_uri()
# does not branch on it. Kept in sync with the file-extension cases handled by
# storage_path_format().
dataset_formats <- c(
  "delta",
  "parquet",
  "csv",
  "tsv",
  "json",
  "avro",
  "orc",
  "text"
)


#' Azure Storage dataset catalog
#'
#' @description
#' An S7 class holding an ordered collection of [az_dataset] objects with
#' unique `name`s.
#'
#' A catalog can be indexed by dataset name with `[[`, and supports `names()`
#' and `length()`.
#'
#' @param datasets A list of [az_dataset] objects.
#'
#' @return An `az_catalog` S7 object.
#' @export
#' @examples
#' ds <- az_dataset(
#'   name = "orders",
#'   scheme = "abfss",
#'   container = "raw",
#'   storage = list(prod = "stprod001"),
#'   path = "sales/orders",
#'   format = "delta"
#' )
#' catalog <- az_catalog(datasets = list(ds))
#'
#' catalog[["orders"]]
#' names(catalog)
#' length(catalog)
az_catalog <- S7::new_class(
  "az_catalog",
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
#' @param format Dataset format. If `NULL`, inferred from the URI's file
#'   extension (e.g. `.parquet`, `.csv`) or `_delta_log` segment. Errors if
#'   `uri` looks like a directory, since the format cannot be inferred from a
#'   directory path; pass `format` explicitly in that case.
#' @param tier Environment tier for the storage account parsed from `uri`.
#'   Defaults to the `dataset_tier` option (`options(azr.dataset_tier = ...)`
#'   or `AZR_DATASET_TIER`, default `"prod"`); see [azr_options()].
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
  tier = opts$get("dataset_tier"),
  storage = NULL
) {
  parsed <- parse_storage_path(uri)
  scheme <- normalise_scheme(parsed$scheme, parsed$endpoint)

  if (is.null(format)) {
    inferred <- parsed$format
    if (is.na(inferred) || identical(inferred, "folder")) {
      cli::cli_abort(c(
        "Cannot infer dataset format from {.val {uri}}.",
        "i" = "A directory URI is ambiguous; pass {.arg format} explicitly,
               e.g. {.code format = \"delta\"}."
      ))
    }
    format <- inferred
  }

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
    format = format,
    endpoint_suffix = parsed$endpoint_suffix %||% "core.windows.net"
  )
}


#' Read a dataset catalog from JSON
#'
#' @description
#' Reads a JSON file describing a collection of datasets and returns an
#' [az_catalog].
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
#' @return An [az_catalog] object.
#' @seealso [az_catalog_write()]
#' @export
az_catalog_read <- function(json_file) {
  raw <- jsonlite::fromJSON(json_file, simplifyVector = FALSE)
  if (!is.list(raw$datasets) || length(raw$datasets) == 0L) {
    cli::cli_abort(
      "JSON must contain a non-empty top-level {.field datasets} array."
    )
  }

  required <- c("name", "scheme", "container", "storage", "path", "format")
  datasets <- lapply(seq_along(raw$datasets), function(i) {
    x <- raw$datasets[[i]]
    missing_fields <- setdiff(required, names(x))
    if (length(missing_fields) > 0L) {
      cli::cli_abort(c(
        "Dataset entry {i} is missing required fields:",
        "*" = "{.field {missing_fields}}"
      ))
    }

    tryCatch(
      az_dataset(
        name = x$name,
        scheme = x$scheme,
        container = x$container,
        storage = x$storage,
        path = x$path,
        format = x$format,
        endpoint_suffix = x$endpoint_suffix %||% "core.windows.net"
      ),
      error = function(e) {
        cli::cli_abort(
          "Dataset entry {i} ({.val {x$name}}) is invalid: {conditionMessage(e)}",
          parent = e
        )
      }
    )
  })

  az_catalog(datasets = datasets)
}


#' Write a dataset catalog to JSON
#'
#' @description
#' Writes an [az_catalog] to a JSON file in the shape expected by
#' [az_catalog_read()].
#'
#' @param catalog An [az_catalog] object.
#' @param json_file Path to write the JSON file to.
#'
#' @return `json_file`, invisibly.
#' @seealso [az_catalog_read()]
#' @export
az_catalog_write <- function(catalog, json_file) {
  if (!S7::S7_inherits(catalog, az_catalog)) {
    cli::cli_abort("{.arg catalog} must be an {.cls az_catalog} object.")
  }
  jsonlite::write_json(
    as.list(catalog),
    path = json_file,
    auto_unbox = TRUE,
    pretty = TRUE
  )
  invisible(json_file)
}


#' Build a URI for an `az_dataset` or look one up in an `az_catalog`
#'
#' @param x An [az_dataset] or [az_catalog] object.
#' @param ... Additional arguments passed to methods:
#'   \describe{
#'     \item{`tier`}{Environment tier name (a key in the dataset's
#'       `storage`). Defaults to the `dataset_tier` option
#'       (`options(azr.dataset_tier = ...)` or `AZR_DATASET_TIER`, default
#'       `"prod"`); see [azr_options()].}
#'     \item{`uri_type`}{URI type: `"https"` or `"hadoop"` (the Hadoop ABFS
#'       URI form `scheme://container@account.dfs.../path`, used by Spark,
#'       Flink, Trino, and any `hadoop-azure` consumer).}
#'     \item{`name`}{For an [az_catalog] only: an optional character scalar
#'       selecting a single dataset by name. If omitted, URIs for every
#'       dataset are returned.}
#'   }
#'
#' @return For an [az_dataset], or an [az_catalog] with `name` supplied, a
#'   character scalar URI. For an [az_catalog] without `name`, a named
#'   character vector of URIs keyed by dataset name.
#' @export
#' @examples
#' ds <- az_dataset(
#'   name = "orders",
#'   scheme = "abfss",
#'   container = "raw",
#'   storage = list(prod = "stprod001"),
#'   path = "sales/orders",
#'   format = "delta"
#' )
#' dataset_uri(ds, tier = "prod")
#'
#' catalog <- az_catalog(datasets = list(ds))
#' dataset_uri(catalog, tier = "prod", name = "orders")
#' dataset_uri(catalog, tier = "prod")
dataset_uri <- S7::new_generic("dataset_uri", "x")

S7::method(dataset_uri, az_dataset) <- function(
  x,
  tier = opts$get("dataset_tier"),
  uri_type = c("hadoop", "https"),
  ...
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

S7::method(dataset_uri, az_catalog) <- function(
  x,
  tier = opts$get("dataset_tier"),
  uri_type = c("hadoop", "https"),
  ...,
  name = NULL
) {
  uri_type <- rlang::arg_match(uri_type)

  if (!is.null(name)) {
    return(dataset_uri(x[[name]], tier = tier, uri_type = uri_type))
  }

  out <- vapply(
    x@datasets,
    function(d) dataset_uri(d, tier = tier, uri_type = uri_type),
    character(1L)
  )
  names(out) <- names(x)
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
S7::method(as.list, az_catalog) <- function(x, ...) {
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

S7::method(print, az_catalog) <- function(x, ...) {
  n <- length(x)
  cli::cli_text(cli::style_bold("<az_catalog>"), " ({n} dataset{?s})")
  for (nm in names(x)) {
    cli::cli_text("  ", nm)
  }
  invisible(x)
}

S7::method(names, az_catalog) <- function(x) {
  vapply(x@datasets, function(d) d@name, character(1L))
}

S7::method(length, az_catalog) <- function(x) {
  length(x@datasets)
}

S7::method(`[[`, az_catalog) <- function(x, i) {
  idx <- which(vapply(
    x@datasets,
    function(d) identical(d@name, i),
    logical(1L)
  ))
  if (length(idx) != 1L) {
    cli::cli_abort(c(
      "Dataset {.val {i}} was not found in the catalog.",
      "i" = "Available: {.val {names(x)}}."
    ))
  }
  x@datasets[[idx]]
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
