# Extracted from test-api-client.R:19

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-client-post-pet", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  # Create a new pet
  pet_data <- list(
    id = 10001L,
    name = "TestDog",
    status = "available",
    category = list(id = 1L, name = "Dogs"),
    tags = list(list(id = 1L, name = "friendly"))
  )

  response <- client$.fetch(
    path = "/pet",
    body = pet_data,
    method = "post",
    content = "body"
  )

  expect_type(response, "list")
  expect_equal(response$name, "TestDog")
  expect_equal(response$status, "available")
  expect_true(!is.null(response$id))
})
