test_that("parses abfss path into correct components", {
  x <- parse_storage_path(
    "abfss://mycontainer@myaccount.dfs.core.windows.net/data/sales/2024"
  )
  expect_s3_class(x, "azure_storage_path")
  expect_equal(x$scheme, "abfss")
  expect_equal(x$storage_account, "myaccount")
  expect_equal(x$endpoint, "dfs")
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "data/sales/2024")
  expect_equal(x$format, "folder")
  expect_null(x$query)
})

test_that("parses abfs path (insecure scheme)", {
  x <- parse_storage_path(
    "abfs://mycontainer@myaccount.dfs.core.windows.net/data/file.parquet"
  )
  expect_equal(x$scheme, "abfs")
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "data/file.parquet")
  expect_equal(x$format, "parquet")
})

test_that("parses az path (adlfs alias of abfs)", {
  x <- parse_storage_path(
    "az://mycontainer@myaccount.dfs.core.windows.net/data/file.parquet"
  )
  expect_equal(x$scheme, "az")
  expect_equal(x$storage_account, "myaccount")
  expect_equal(x$endpoint, "dfs")
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "data/file.parquet")
  expect_equal(x$format, "parquet")
})

test_that("parses azure path (alias of abfs)", {
  x <- parse_storage_path(
    "azure://mycontainer@myaccount.dfs.core.windows.net/data/sales"
  )
  expect_equal(x$scheme, "azure")
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "data/sales")
})

test_that("parses wasbs path", {
  x <- parse_storage_path(
    "wasbs://mycontainer@myaccount.blob.core.windows.net/data/"
  )
  expect_equal(x$scheme, "wasbs")
  expect_equal(x$endpoint, "blob")
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "data/")
  expect_equal(x$format, "folder")
})

test_that("parses https blob path", {
  x <- parse_storage_path(
    "https://myaccount.blob.core.windows.net/mycontainer/data/file.csv"
  )
  expect_equal(x$scheme, "https")
  expect_equal(x$storage_account, "myaccount")
  expect_equal(x$endpoint, "blob")
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "data/file.csv")
  expect_equal(x$format, "csv")
})

test_that("parses https dfs path", {
  x <- parse_storage_path(
    "https://myaccount.dfs.core.windows.net/mycontainer/data/events"
  )
  expect_equal(x$endpoint, "dfs")
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "data/events")
  expect_equal(x$format, "folder")
})

test_that("parses SAS token query string", {
  x <- parse_storage_path(
    "https://myaccount.blob.core.windows.net/mycontainer/data/file.parquet?sv=2021-06-08&sig=abc123"
  )
  expect_equal(x$format, "parquet")
  expect_equal(x$query$sv, "2021-06-08")
  expect_equal(x$query$sig, "abc123")
})

test_that("detects delta format from _delta_log in path", {
  x <- parse_storage_path(
    "abfss://mycontainer@myaccount.dfs.core.windows.net/data/my_table/_delta_log"
  )
  expect_equal(x$format, "delta")
})

test_that("detects delta format when _delta_log appears anywhere in path", {
  x <- parse_storage_path(
    "https://myaccount.dfs.core.windows.net/mycontainer/data/_delta_log/00001.json"
  )
  expect_equal(x$format, "delta")
})

test_that("format detection covers common file types", {
  cases <- list(
    list(ext = "file.json", fmt = "json"),
    list(ext = "file.jsonl", fmt = "json"),
    list(ext = "file.avro", fmt = "avro"),
    list(ext = "file.orc", fmt = "orc"),
    list(ext = "file.tsv", fmt = "tsv"),
    list(ext = "file.txt", fmt = "text"),
    list(ext = "file.unknown", fmt = NA_character_)
  )
  for (case in cases) {
    path <- paste0("abfss://c@a.dfs.core.windows.net/data/", case$ext)
    x <- parse_storage_path(path)
    expect_equal(x$format, case$fmt, info = case$ext)
  }
})

test_that("path is empty string at container root for abfss", {
  x <- parse_storage_path(
    "abfss://mycontainer@myaccount.dfs.core.windows.net/"
  )
  expect_equal(x$path, "")
  expect_equal(x$container, "mycontainer")
})

test_that("path is empty string at container root for https", {
  x <- parse_storage_path(
    "https://myaccount.blob.core.windows.net/mycontainer"
  )
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "")
})

test_that("original field preserves input", {
  input <- "abfss://mycontainer@myaccount.dfs.core.windows.net/data/sales"
  x <- parse_storage_path(input)
  expect_equal(x$original, input)
})

test_that("errors on unsupported scheme", {
  expect_error(parse_storage_path("s3://bucket/key"), class = "rlang_error")
})

test_that("errors on non-string input", {
  expect_error(parse_storage_path(123), class = "rlang_error")
  expect_error(parse_storage_path(""), class = "rlang_error")
})

test_that("errors with clear message on degenerate URL with empty authority", {
  # abfss:///path has no host — httr2 misparses the first path segment as
  # the hostname, producing a single-label host with no account info.
  expect_error(
    parse_storage_path("abfss:///path"),
    regexp = "Invalid storage hostname",
    class = "rlang_error"
  )
})

test_that("print method returns invisibly", {
  x <- parse_storage_path(
    "abfss://mycontainer@myaccount.dfs.core.windows.net/data"
  )
  expect_invisible(print(x))
})

test_that("captures endpoint_suffix for Azure public cloud", {
  x <- parse_storage_path(
    "abfss://c@a.dfs.core.windows.net/data"
  )
  expect_equal(x$endpoint_suffix, "core.windows.net")
})

test_that("captures endpoint_suffix for US Government cloud", {
  x <- parse_storage_path(
    "https://a.blob.core.usgovcloudapi.net/c/data/file.csv"
  )
  expect_equal(x$storage_account, "a")
  expect_equal(x$endpoint, "blob")
  expect_equal(x$endpoint_suffix, "core.usgovcloudapi.net")
})

test_that("captures endpoint_suffix for China cloud", {
  x <- parse_storage_path(
    "https://a.dfs.core.chinacloudapi.cn/c/data"
  )
  expect_equal(x$endpoint, "dfs")
  expect_equal(x$endpoint_suffix, "core.chinacloudapi.cn")
})

test_that("handles DNS-zone endpoints without warning", {
  expect_no_warning(
    x <- parse_storage_path(
      "https://myaccount.z42.blob.storage.azure.net/mycontainer/data/file.parquet"
    )
  )
  expect_equal(x$storage_account, "myaccount")
  expect_equal(x$endpoint, "blob")
  expect_equal(x$endpoint_suffix, "storage.azure.net")
  expect_equal(x$container, "mycontainer")
  expect_equal(x$path, "data/file.parquet")
})
