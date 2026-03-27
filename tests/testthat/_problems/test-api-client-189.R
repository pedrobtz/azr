# Extracted from test-api-client.R:189

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-client-response", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  response <- client$.fetch(
    path = "/pet/findByStatus",
    query = list(status = "available"),
    method = "get",
    content = "response"
  )

  expect_s3_class(response, "httr2_response")
  expect_true(!is.null(response$status_code))
  expect_equal(response$status_code, 200)
})
