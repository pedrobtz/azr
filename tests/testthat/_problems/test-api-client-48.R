# Extracted from test-api-client.R:48

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-client-get-pet", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  # First create a pet to ensure we have a valid ID
  pet_id <- 10002L
  pet_data <- list(
    id = pet_id,
    name = "GetTestDog",
    status = "available"
  )

  # POST the pet
  post_response <- client$.fetch(
    path = "/pet",
    body = pet_data,
    method = "post",
    content = "body"
  )

  # GET the pet by ID
  get_response <- client$.fetch(
    path = "/pet/{petId}",
    petId = post_response$id,
    method = "get",
    content = "body"
  )

  expect_type(get_response, "list")
  expect_equal(get_response$id, post_response$id)
  expect_equal(get_response$name, "GetTestDog")
  expect_equal(get_response$status, "available")
})
