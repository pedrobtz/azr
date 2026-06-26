test_that("azr_dataset constructs with valid inputs", {
  ds <- azr_dataset(
    name = "sales_orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )

  expect_true(S7::S7_inherits(ds, azr_dataset))
  expect_equal(ds@name, "sales_orders")
  expect_equal(ds@endpoint_suffix, "core.windows.net")
})

test_that("azr_dataset rejects invalid name", {
  expect_error(
    azr_dataset(
      name = "Sales-Orders",
      scheme = "abfss",
      container = "raw",
      storage = list(prod = "stprod001"),
      path = "sales/orders",
      format = "delta"
    ),
    "name must match"
  )
})

test_that("azr_dataset rejects invalid container", {
  expect_error(
    azr_dataset(
      name = "ds",
      scheme = "abfss",
      container = "AB",
      storage = list(prod = "stprod001"),
      path = "sales/orders",
      format = "delta"
    ),
    "container"
  )
})

test_that("azr_dataset rejects path with leading/trailing slash", {
  expect_error(
    azr_dataset(
      name = "ds",
      scheme = "abfss",
      container = "raw",
      storage = list(prod = "stprod001"),
      path = "/sales/orders",
      format = "delta"
    ),
    "path"
  )
})

test_that("azr_dataset accepts the full documented format vocabulary", {
  for (fmt in c(
    "delta",
    "parquet",
    "csv",
    "tsv",
    "json",
    "avro",
    "orc",
    "text"
  )) {
    ds <- azr_dataset(
      name = "ds",
      scheme = "abfss",
      container = "raw",
      storage = list(prod = "stprod001"),
      path = "sales/orders",
      format = fmt
    )
    expect_equal(ds@format, fmt)
  }
})

test_that("azr_dataset rejects unknown format", {
  expect_error(
    azr_dataset(
      name = "ds",
      scheme = "abfss",
      container = "raw",
      storage = list(prod = "stprod001"),
      path = "sales/orders",
      format = "bogus"
    ),
    "format"
  )
})

test_that("azr_dataset_from_uri parses abfss URI", {
  ds <- azr_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders.parquet",
    name = "sales_orders"
  )

  expect_equal(ds@scheme, "abfss")
  expect_equal(ds@container, "raw")
  expect_equal(ds@path, "sales/orders.parquet")
  expect_equal(ds@storage$prod, "stprod001")
  expect_equal(ds@format, "parquet")
})

test_that("azr_dataset_from_uri parses https URI to abfss", {
  ds <- azr_dataset_from_uri(
    uri = "https://stprod001.dfs.core.windows.net/raw/sales/orders.csv",
    name = "sales_orders"
  )

  expect_equal(ds@scheme, "abfss")
  expect_equal(ds@container, "raw")
  expect_equal(ds@path, "sales/orders.csv")
  expect_equal(ds@format, "csv")
})

test_that("azr_dataset_from_uri keeps existing storage entries", {
  ds <- azr_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders.delta/_delta_log",
    name = "sales_orders",
    format = "delta",
    tier = "prod",
    storage = list(prod = "explicit_prod", preprod = "stpreprod001")
  )

  expect_equal(ds@storage$prod, "explicit_prod")
  expect_equal(ds@storage$preprod, "stpreprod001")
})

test_that("azr_dataset_from_uri infers delta format from _delta_log path", {
  ds <- azr_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders/_delta_log",
    name = "sales_orders"
  )

  expect_equal(ds@format, "delta")
})

test_that("azr_dataset_from_uri defaults to delta on a directory URI", {
  ds <- azr_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
    name = "sales_orders"
  )

  expect_equal(ds@format, "delta")
  expect_equal(ds@path, "sales/orders")
})

test_that("azr_dataset_from_uri errors on an unrecognised file extension", {
  expect_error(
    azr_dataset_from_uri(
      uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders.xyz",
      name = "sales_orders"
    ),
    "Cannot infer dataset format"
  )
})

test_that("azr_dataset_from_uri directory URI works with explicit format", {
  ds <- azr_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
    name = "sales_orders",
    format = "delta"
  )

  expect_equal(ds@format, "delta")
  expect_equal(ds@path, "sales/orders")
})

test_that("azr_dataset_from_uri derives name from the last path segment", {
  ds <- azr_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
    format = "delta"
  )
  expect_equal(ds@name, "orders")
})

test_that("azr_dataset_from_uri derived name strips the file extension", {
  ds <- azr_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders.parquet"
  )
  expect_equal(ds@name, "orders")
})

test_that("azr_dataset_from_uri uses the dataset_tier option as the default tier", {
  withr::local_options(azr.dataset_tier = "preprod")

  ds <- azr_dataset_from_uri(
    uri = "abfss://raw@stpreprod001.dfs.core.windows.net/sales/orders.parquet",
    name = "sales_orders"
  )

  expect_named(ds@storage, "preprod")
  expect_equal(ds@storage$preprod, "stpreprod001")
})

test_that("azr_dataset_uri builds hadoop (default) and https URIs", {
  ds <- azr_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )

  expect_equal(
    azr_dataset_uri(ds, tier = "prod"),
    "abfss://raw@stprod001.dfs.core.windows.net/sales/orders"
  )
  expect_equal(
    azr_dataset_uri(ds, tier = "prod", uri_type = "https"),
    "https://stprod001.dfs.core.windows.net/raw/sales/orders"
  )
})

test_that("azr_dataset_uri defaults tier to the dataset_tier option", {
  withr::local_options(azr.dataset_tier = "preprod")

  ds <- azr_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001", preprod = "stpreprod001"),
    path = "sales/orders",
    format = "delta"
  )

  expect_equal(
    azr_dataset_uri(ds),
    "abfss://raw@stpreprod001.dfs.core.windows.net/sales/orders"
  )
})

test_that("azr_dataset_uri errors on unknown tier", {
  ds <- azr_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )

  expect_error(
    azr_dataset_uri(ds, tier = "uat", uri_type = "https"),
    "Unknown tier"
  )
})

test_that("azr_catalog rejects duplicate dataset names", {
  ds1 <- azr_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "a"),
    path = "p",
    format = "delta"
  )
  ds2 <- azr_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "b"),
    path = "p",
    format = "delta"
  )

  expect_error(azr_catalog(datasets = list(ds1, ds2)), "unique")
})

test_that("azr_catalog supports `[[`, names(), and length()", {
  ds1 <- azr_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )
  ds2 <- azr_dataset(
    name = "products",
    scheme = "wasbs",
    container = "raw",
    storage = list(prod = "stprod002"),
    path = "ref/products",
    format = "parquet"
  )
  catalog <- azr_catalog(datasets = list(ds1, ds2))

  expect_equal(names(catalog), c("orders", "products"))
  expect_equal(length(catalog), 2L)
  expect_true(S7::S7_inherits(catalog[["orders"]], azr_dataset))
  expect_equal(catalog[["orders"]]@name, "orders")
})

test_that("azr_catalog `[[` errors on unknown dataset and lists available names", {
  ds1 <- azr_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )
  catalog <- azr_catalog(datasets = list(ds1))

  expect_error(catalog[["missing"]], "orders")
})

test_that("azr_dataset_uri on azr_catalog looks up by name and lists all", {
  ds1 <- azr_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )
  ds2 <- azr_dataset(
    name = "products",
    scheme = "wasbs",
    container = "raw",
    storage = list(prod = "stprod002"),
    path = "ref/products",
    format = "parquet"
  )
  catalog <- azr_catalog(datasets = list(ds1, ds2))

  expect_equal(
    azr_dataset_uri(catalog, tier = "prod", uri_type = "https", name = "orders"),
    "https://stprod001.dfs.core.windows.net/raw/sales/orders"
  )

  uris <- azr_dataset_uri(catalog, tier = "prod", uri_type = "https")
  expect_named(uris, c("orders", "products"))
  expect_length(uris, 2L)
})

test_that("as.list round-trips through jsonlite::toJSON", {
  ds <- azr_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )
  catalog <- azr_catalog(datasets = list(ds))

  json <- jsonlite::toJSON(as.list(catalog), auto_unbox = TRUE)
  parsed <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  expect_equal(parsed$datasets[[1]]$name, "orders")
  expect_equal(parsed$datasets[[1]]$container, "raw")
})

test_that("azr_catalog_write and azr_catalog_read round-trip", {
  ds1 <- azr_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001", preprod = "stpreprod001"),
    path = "sales/orders",
    format = "delta"
  )
  ds2 <- azr_dataset(
    name = "products",
    scheme = "wasbs",
    container = "raw",
    storage = list(prod = "stprod002"),
    path = "ref/products",
    format = "parquet"
  )
  catalog <- azr_catalog(datasets = list(ds1, ds2))

  json_file <- withr::local_tempfile(fileext = ".json")
  azr_catalog_write(catalog, json_file)

  roundtripped <- azr_catalog_read(json_file)
  expect_equal(names(roundtripped), names(catalog))
  expect_equal(roundtripped[["orders"]]@storage, ds1@storage)
  expect_equal(roundtripped[["products"]]@format, "parquet")
})

test_that("azr_catalog_write errors on non-catalog input", {
  expect_error(
    azr_catalog_write(list(), tempfile(fileext = ".json")),
    "azr_catalog"
  )
})

test_that("azr_catalog_read reads JSON file", {
  json_file <- withr::local_tempfile(fileext = ".json")
  writeLines(
    '{
      "datasets": [
        {
          "name": "orders",
          "scheme": "abfss",
          "container": "raw",
          "storage": { "prod": "stprod001", "preprod": "stpreprod001" },
          "path": "sales/orders",
          "format": "delta"
        }
      ]
    }',
    json_file
  )

  catalog <- azr_catalog_read(json_file)
  expect_true(S7::S7_inherits(catalog, azr_catalog))
  expect_length(catalog, 1L)
  expect_equal(catalog[["orders"]]@name, "orders")
})

test_that("azr_catalog_read errors on missing required fields, naming the entry", {
  json_file <- withr::local_tempfile(fileext = ".json")
  writeLines(
    '{"datasets":[{"name":"orders"}]}',
    json_file
  )

  expect_error(
    azr_catalog_read(json_file),
    "Dataset entry 1 is missing required fields"
  )
})

test_that("azr_dataset_manifest validates and converts to a list", {
  manifest <- azr_dataset_manifest(
    name = "orders",
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
    format = "delta"
  )

  expect_s7_class(manifest, azr_dataset_manifest)
  expect_equal(
    as.list(manifest),
    list(
      name = "orders",
      uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
      format = "delta"
    )
  )

  expect_error(
    azr_dataset_manifest(name = "", uri = "https://example.com", format = "delta"),
    "name"
  )
  expect_error(
    azr_dataset_manifest(name = "orders", uri = "", format = "delta"),
    "uri"
  )
  expect_error(
    azr_dataset_manifest(
      name = "orders",
      uri = "https://example.com",
      format = "bogus"
    ),
    "format"
  )
})

test_that("azr_resolve_dataset on azr_dataset returns a manifest", {
  ds <- azr_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )

  manifest <- azr_resolve_dataset(ds, tier = "prod")
  expect_s7_class(manifest, azr_dataset_manifest)
  expect_equal(
    as.list(manifest),
    list(
      name = "orders",
      uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
      format = "delta"
    )
  )
})

test_that("azr_resolve_dataset on azr_catalog looks up by name and lists all", {
  ds1 <- azr_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )
  ds2 <- azr_dataset(
    name = "products",
    scheme = "wasbs",
    container = "raw",
    storage = list(prod = "stprod002"),
    path = "ref/products",
    format = "parquet"
  )
  catalog <- azr_catalog(datasets = list(ds1, ds2))

  orders <- azr_resolve_dataset(catalog, tier = "prod", name = "orders")
  expect_s7_class(orders, azr_dataset_manifest)
  expect_equal(
    as.list(orders),
    list(
      name = "orders",
      uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
      format = "delta"
    )
  )

  manifest <- azr_resolve_dataset(catalog, tier = "prod", uri_type = "https")
  expect_named(manifest, c("orders", "products"))
  expect_s7_class(manifest$products, azr_dataset_manifest)
  expect_equal(
    as.list(manifest$products),
    list(
      name = "products",
      uri = "https://stprod002.blob.core.windows.net/raw/ref/products",
      format = "parquet"
    )
  )
})

test_that("azr_catalog_read errors with the entry index and name on invalid dataset", {
  json_file <- withr::local_tempfile(fileext = ".json")
  writeLines(
    '{
      "datasets": [
        {
          "name": "orders",
          "scheme": "abfss",
          "container": "raw",
          "storage": { "prod": "stprod001" },
          "path": "sales/orders",
          "format": "bogus"
        }
      ]
    }',
    json_file
  )

  expect_error(
    azr_catalog_read(json_file),
    "Dataset entry 1 \\(\"orders\"\\) is invalid"
  )
})
