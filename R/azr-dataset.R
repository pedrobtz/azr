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
#' cloud, model it as a separate [azr_dataset].
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
#' @return An `azr_dataset` S7 object.
#' @export
azr_dataset <- S7::new_class(
  "azr_dataset",
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
#' An S7 class holding an ordered collection of [azr_dataset] objects with
#' unique `name`s.
#'
#' A catalog can be indexed by dataset name with `[[`, and supports `names()`
#' and `length()`.
#'
#' @param datasets A list of [azr_dataset] objects.
#'
#' @return An `azr_catalog` S7 object.
#' @export
#' @examples
#' ds <- azr_dataset(
#'   name = "orders",
#'   scheme = "abfss",
#'   container = "raw",
#'   storage = list(prod = "stprod001"),
#'   path = "sales/orders",
#'   format = "delta"
#' )
#' catalog <- azr_catalog(datasets = list(ds))
#'
#' catalog[["orders"]]
#' names(catalog)
#' length(catalog)
azr_catalog <- S7::new_class(
  "azr_catalog",
  properties = list(
    datasets = S7::class_list
  ),
  validator = function(self) {
    if (
      !all(vapply(
        self@datasets,
        function(d) S7::S7_inherits(d, azr_dataset),
        logical(1L)
      ))
    ) {
      return("datasets must be a list of azr_dataset objects")
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


#' Azure Storage dataset manifest
#'
#' @description
#' An S7 class representing the resolved information required by an external
#' reader to load an Azure Storage dataset. Use [as.list()][base::as.list] to
#' convert it to a plain R list.
#'
#' @param name Dataset name, carried over from the source [azr_dataset].
#' @param uri Resolved Azure Storage URI.
#' @param format Dataset format. See [azr_dataset] for supported values.
#'
#' @return An `azr_dataset_manifest` S7 object.
#' @export
azr_dataset_manifest <- S7::new_class(
  "azr_dataset_manifest",
  properties = list(
    name = S7::class_character,
    uri = S7::class_character,
    format = S7::class_character
  ),
  validator = function(self) {
    if (!is_scalar_string(self@name)) {
      return("name must be a non-empty character scalar")
    }
    if (!is_scalar_string(self@uri)) {
      return("uri must be a non-empty character scalar")
    }
    if (!self@format %in% dataset_formats) {
      return(paste0(
        "format must be one of: ",
        paste(dataset_formats, collapse = ", ")
      ))
    }
    NULL
  }
)


#' Create an `azr_dataset` from a full Azure Storage URI
#'
#' @description
#' Parses an Azure Storage URI using [parse_storage_path()] and constructs an
#' [azr_dataset]. The parsed storage account is bound to `tier` in `storage`.
#'
#' @param uri Full Azure Storage URI, such as
#'   `abfss://raw@account.dfs.core.windows.net/path` or
#'   `https://account.dfs.core.windows.net/raw/path`.
#' @param name Dataset name. If `NULL` (the default), derived from the last
#'   segment of the URI's path with any file extension removed, e.g. `"orders"`
#'   for `.../sales/orders` or `.../sales/orders.parquet`.
#' @param format Dataset format. If `NULL`, inferred from the URI's file
#'   extension (e.g. `.parquet`, `.csv`) or `_delta_log` segment. Defaults to
#'   `"delta"` when `uri` looks like a directory. Errors only when `uri` has a
#'   file extension that maps to no known format; pass `format` explicitly then.
#' @param tier Environment tier for the storage account parsed from `uri`.
#'   Defaults to the `dataset_tier` option (`options(azr.dataset_tier = ...)`
#'   or `AZR_DATASET_TIER`, default `"prod"`); see [azr_options()].
#' @param storage Optional named list mapping additional tiers to storage
#'   accounts. The account from `uri` is bound to `tier` unless that key is
#'   already present.
#'
#' @return An [azr_dataset] object.
#' @export
azr_dataset_from_uri <- function(
  uri,
  name = NULL,
  format = NULL,
  tier = opts$get("dataset_tier"),
  storage = NULL
) {
  parsed <- parse_storage_path(uri)
  scheme <- normalise_scheme(parsed$scheme, parsed$endpoint)

  if (is.null(name)) {
    name <- tools::file_path_sans_ext(basename(parsed$path))
  }

  if (is.null(format)) {
    inferred <- parsed$format
    format <- if (identical(inferred, "folder")) {
      "delta"
    } else if (is.na(inferred)) {
      cli::cli_abort(c(
        "Cannot infer dataset format from {.val {uri}}.",
        "i" = "The path has an unrecognised file extension; pass {.arg format}
               explicitly, e.g. {.code format = \"parquet\"}."
      ))
    } else {
      inferred
    }
  }

  storage <- if (is.null(storage)) {
    stats::setNames(list(parsed$storage_account), tier)
  } else {
    storage <- as.list(storage)
    storage[[tier]] <- storage[[tier]] %||% parsed$storage_account
    storage
  }

  azr_dataset(
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
#' [azr_catalog].
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
#' @return An [azr_catalog] object.
#' @seealso [azr_catalog_write()]
#' @export
azr_catalog_read <- function(json_file) {
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
      azr_dataset(
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

  azr_catalog(datasets = datasets)
}


#' Write a dataset catalog to JSON
#'
#' @description
#' Writes an [azr_catalog] to a JSON file in the shape expected by
#' [azr_catalog_read()].
#'
#' @param catalog An [azr_catalog] object.
#' @param json_file Path to write the JSON file to.
#'
#' @return `json_file`, invisibly.
#' @seealso [azr_catalog_read()]
#' @export
azr_catalog_write <- function(catalog, json_file) {
  if (!S7::S7_inherits(catalog, azr_catalog)) {
    cli::cli_abort("{.arg catalog} must be an {.cls azr_catalog} object.")
  }
  jsonlite::write_json(
    as.list(catalog),
    path = json_file,
    auto_unbox = TRUE,
    pretty = TRUE
  )
  invisible(json_file)
}


#' Build a URI for an `azr_dataset` or look one up in an `azr_catalog`
#'
#' @param x An [azr_dataset] or [azr_catalog] object.
#' @param ... Additional arguments passed to methods:
#'   \describe{
#'     \item{`tier`}{Environment tier name (a key in the dataset's
#'       `storage`). Defaults to the `dataset_tier` option
#'       (`options(azr.dataset_tier = ...)` or `AZR_DATASET_TIER`, default
#'       `"prod"`); see [azr_options()].}
#'     \item{`uri_type`}{URI type: `"https"` or `"hadoop"` (the Hadoop ABFS
#'       URI form `scheme://container@account.dfs.../path`, used by Spark,
#'       Flink, Trino, and any `hadoop-azure` consumer).}
#'     \item{`name`}{For an [azr_catalog] only: an optional character scalar
#'       selecting a single dataset by name. If omitted, URIs for every
#'       dataset are returned.}
#'   }
#'
#' @return For an [azr_dataset], or an [azr_catalog] with `name` supplied, a
#'   character scalar URI. For an [azr_catalog] without `name`, a named
#'   character vector of URIs keyed by dataset name.
#' @export
#' @examples
#' ds <- azr_dataset(
#'   name = "orders",
#'   scheme = "abfss",
#'   container = "raw",
#'   storage = list(prod = "stprod001"),
#'   path = "sales/orders",
#'   format = "delta"
#' )
#' azr_dataset_uri(ds, tier = "prod")
#'
#' catalog <- azr_catalog(datasets = list(ds))
#' azr_dataset_uri(catalog, tier = "prod", name = "orders")
#' azr_dataset_uri(catalog, tier = "prod")
azr_dataset_uri <- S7::new_generic("azr_dataset_uri", "x")

S7::method(azr_dataset_uri, azr_dataset) <- function(
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

S7::method(azr_dataset_uri, azr_catalog) <- function(
  x,
  tier = opts$get("dataset_tier"),
  uri_type = c("hadoop", "https"),
  ...,
  name = NULL
) {
  uri_type <- rlang::arg_match(uri_type)

  if (!is.null(name)) {
    return(azr_dataset_uri(x[[name]], tier = tier, uri_type = uri_type))
  }

  out <- vapply(
    x@datasets,
    function(d) azr_dataset_uri(d, tier = tier, uri_type = uri_type),
    character(1L)
  )
  names(out) <- names(x)
  out
}


#' Build a URI + format manifest for an `azr_dataset` or `azr_catalog`
#'
#' @description
#' Like [azr_dataset_uri()], but each entry also carries the dataset's `format`,
#' which together are what a reader (e.g. `sparklyr::spark_read_source()`)
#' needs to load a dataset.
#'
#' @inheritParams azr_dataset_uri
#'
#' @return For an [azr_dataset], or an [azr_catalog] with `name` supplied, an
#'   [azr_dataset_manifest]. For an [azr_catalog] without `name`, a named list
#'   of `azr_dataset_manifest` objects, keyed by dataset name.
#' @export
#' @examples
#' ds <- azr_dataset(
#'   name = "orders",
#'   scheme = "abfss",
#'   container = "raw",
#'   storage = list(prod = "stprod001"),
#'   path = "sales/orders",
#'   format = "delta"
#' )
#' azr_resolve_dataset(ds, tier = "prod")
#'
#' catalog <- azr_catalog(datasets = list(ds))
#' azr_resolve_dataset(catalog, tier = "prod")
azr_resolve_dataset <- S7::new_generic("azr_resolve_dataset", "x")

S7::method(azr_resolve_dataset, azr_dataset) <- function(
  x,
  tier = opts$get("dataset_tier"),
  uri_type = c("hadoop", "https"),
  ...
) {
  uri_type <- rlang::arg_match(uri_type)
  azr_dataset_manifest(
    name = x@name,
    uri = azr_dataset_uri(x, tier = tier, uri_type = uri_type),
    format = x@format
  )
}

S7::method(azr_resolve_dataset, azr_catalog) <- function(
  x,
  tier = opts$get("dataset_tier"),
  uri_type = c("hadoop", "https"),
  ...,
  name = NULL
) {
  uri_type <- rlang::arg_match(uri_type)

  if (!is.null(name)) {
    return(azr_resolve_dataset(x[[name]], tier = tier, uri_type = uri_type))
  }

  out <- lapply(
    x@datasets,
    function(d) azr_resolve_dataset(d, tier = tier, uri_type = uri_type)
  )
  names(out) <- names(x)
  out
}


# S3 methods registered via S7 (S7 namespaces class to "pkg::class") ------

# nolint next: object_name_linter.
S7::method(as.list, azr_dataset) <- function(x, ...) {
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
S7::method(as.list, azr_catalog) <- function(x, ...) {
  list(datasets = lapply(x@datasets, as.list))
}

# nolint next: object_name_linter.
S7::method(as.list, azr_dataset_manifest) <- function(x, ...) {
  list(
    name = x@name,
    uri = x@uri,
    format = x@format
  )
}

S7::method(print, azr_dataset) <- function(x, ...) {
  cli::cli_text(cli::style_bold("<azr_dataset:{x@name}>"))
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

S7::method(print, azr_dataset_manifest) <- function(x, ...) {
  cli::cli_text(cli::style_bold("<azr_dataset_manifest:{x@name}>"))
  cli::cli_dl(c(
    uri = x@uri,
    format = x@format
  ))
  invisible(x)
}

S7::method(print, azr_catalog) <- function(x, ...) {
  n <- length(x)
  cli::cli_text(cli::style_bold("<azr_catalog>"), " ({n} dataset{?s})")
  for (nm in names(x)) {
    cli::cli_text("  ", nm)
  }
  invisible(x)
}

S7::method(names, azr_catalog) <- function(x) {
  vapply(x@datasets, function(d) d@name, character(1L))
}

S7::method(length, azr_catalog) <- function(x) {
  length(x@datasets)
}

S7::method(`[[`, azr_catalog) <- function(x, i) {
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
