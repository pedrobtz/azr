# Extracted from test-api-client.R:6

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
client <- api_client$new(
  host_url = "https://petstore.swagger.io/v2",
  timeout = 30L,
  max_tries = 3L
)
