# Extracted from test-api-client.R:241

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-client-404", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  # Request a pet that doesn't exist
  expect_error(
    client$.fetch(
      path = "/pet/{petId}",
      petId = 99999999L,
      method = "get",
      content = "body"
    ),
    class = "httr2_http_404"
  )
})
