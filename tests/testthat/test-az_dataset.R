test_that("az_dataset constructs with valid inputs", {
  ds <- az_dataset(
    name = "sales_orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )

  expect_true(S7::S7_inherits(ds, az_dataset))
  expect_equal(ds@name, "sales_orders")
  expect_equal(ds@endpoint_suffix, "core.windows.net")
})

test_that("az_dataset rejects invalid name", {
  expect_error(
    az_dataset(
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

test_that("az_dataset rejects invalid container", {
  expect_error(
    az_dataset(
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

test_that("az_dataset rejects path with leading/trailing slash", {
  expect_error(
    az_dataset(
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

test_that("az_dataset rejects unknown format", {
  expect_error(
    az_dataset(
      name = "ds",
      scheme = "abfss",
      container = "raw",
      storage = list(prod = "stprod001"),
      path = "sales/orders",
      format = "avro"
    ),
    "format"
  )
})

test_that("az_dataset_from_uri parses abfss URI", {
  ds <- az_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
    name = "sales_orders",
    format = "delta"
  )

  expect_equal(ds@scheme, "abfss")
  expect_equal(ds@container, "raw")
  expect_equal(ds@path, "sales/orders")
  expect_equal(ds@storage$prod, "stprod001")
})

test_that("az_dataset_from_uri parses https URI to abfss", {
  ds <- az_dataset_from_uri(
    uri = "https://stprod001.dfs.core.windows.net/raw/sales/orders",
    name = "sales_orders",
    format = "delta"
  )

  expect_equal(ds@scheme, "abfss")
  expect_equal(ds@container, "raw")
  expect_equal(ds@path, "sales/orders")
})

test_that("az_dataset_from_uri keeps existing storage entries", {
  ds <- az_dataset_from_uri(
    uri = "abfss://raw@stprod001.dfs.core.windows.net/sales/orders",
    name = "sales_orders",
    format = "delta",
    tier = "prod",
    storage = list(prod = "explicit_prod", preprod = "stpreprod001")
  )

  expect_equal(ds@storage$prod, "explicit_prod")
  expect_equal(ds@storage$preprod, "stpreprod001")
})

test_that("dataset_uri builds hadoop (default) and https URIs", {
  ds <- az_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )

  expect_equal(
    dataset_uri(ds, tier = "prod"),
    "abfss://raw@stprod001.dfs.core.windows.net/sales/orders"
  )
  expect_equal(
    dataset_uri(ds, tier = "prod", uri_type = "https"),
    "https://stprod001.dfs.core.windows.net/raw/sales/orders"
  )
})

test_that("dataset_uri errors on unknown tier", {
  ds <- az_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )

  expect_error(
    dataset_uri(ds, tier = "uat", uri_type = "https"),
    "Unknown tier"
  )
})

test_that("az_data_catalog rejects duplicate dataset names", {
  ds1 <- az_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "a"),
    path = "p",
    format = "delta"
  )
  ds2 <- az_dataset(
    name = "ds",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "b"),
    path = "p",
    format = "delta"
  )

  expect_error(az_data_catalog(datasets = list(ds1, ds2)), "unique")
})

test_that("lookup_dataset_uri and catalog_dataset_uris work", {
  ds1 <- az_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )
  ds2 <- az_dataset(
    name = "products",
    scheme = "wasbs",
    container = "raw",
    storage = list(prod = "stprod002"),
    path = "ref/products",
    format = "parquet"
  )
  catalog <- az_data_catalog(datasets = list(ds1, ds2))

  expect_equal(
    lookup_dataset_uri(catalog, "orders", tier = "prod", uri_type = "https"),
    "https://stprod001.dfs.core.windows.net/raw/sales/orders"
  )

  uris <- catalog_dataset_uris(catalog, tier = "prod", uri_type = "https")
  expect_named(uris, c("orders", "products"))
  expect_length(uris, 2L)
})

test_that("as.list round-trips through jsonlite::toJSON", {
  ds <- az_dataset(
    name = "orders",
    scheme = "abfss",
    container = "raw",
    storage = list(prod = "stprod001"),
    path = "sales/orders",
    format = "delta"
  )
  catalog <- az_data_catalog(datasets = list(ds))

  json <- jsonlite::toJSON(as.list(catalog), auto_unbox = TRUE)
  parsed <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  expect_equal(parsed$datasets[[1]]$name, "orders")
  expect_equal(parsed$datasets[[1]]$container, "raw")
})

test_that("load_dataset_catalog reads JSON file", {
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

  catalog <- load_dataset_catalog(json_file)
  expect_true(S7::S7_inherits(catalog, az_data_catalog))
  expect_length(catalog@datasets, 1L)
  expect_equal(catalog@datasets[[1]]@name, "orders")
})

test_that("load_dataset_catalog errors on missing required fields", {
  json_file <- withr::local_tempfile(fileext = ".json")
  writeLines(
    '{"datasets":[{"name":"orders"}]}',
    json_file
  )

  expect_error(load_dataset_catalog(json_file), "missing required fields")
})
