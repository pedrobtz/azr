# Extracted from test-api-client.R:170

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-client-headers", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  headers <- client$.fetch(
    path = "/pet/findByStatus",
    query = list(status = "available"),
    method = "get",
    content = "headers"
  )

  expect_type(headers, "list")
  expect_true(length(headers) > 0)
  expect_true("content-type" %in% names(headers))
})
