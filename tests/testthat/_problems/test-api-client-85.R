# Extracted from test-api-client.R:85

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-client-get-by-status", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  # First create a pet with known status to ensure we have data
  pet_id <- 10003L
  pet_data <- list(
    id = pet_id,
    name = "StatusTestPet",
    status = "pending",
    photoUrls = list("https://example.com/photo.jpg")
  )

  client$.fetch(
    path = "/pet",
    body = pet_data,
    method = "post",
    content = "body"
  )

  # GET pets with 'pending' status using query parameters
  response <- client$.fetch(
    path = "/pet/findByStatus",
    query = list(status = "pending"),
    method = "get",
    content = "body"
  )

  expect_type(response, "list")
  expect_true(length(response) > 0)

  # Verify we can find our created pet
  expect_true(pet_id %in% response$id)

  # Verify all returned pets have pending status
  expect_true(all("pending" == response$status))
})
