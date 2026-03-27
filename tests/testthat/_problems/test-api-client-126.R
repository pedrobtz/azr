# Extracted from test-api-client.R:126

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-client-put-update", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  # Create a pet first
  pet_id <- 10004L
  pet_data <- list(
    id = pet_id,
    name = "OriginalName",
    status = "available",
    photoUrls = list("https://example.com/photo.jpg")
  )

  post_response <- client$.fetch(
    path = "/pet",
    body = pet_data,
    method = "post",
    content = "body"
  )

  # Update the pet
  updated_data <- list(
    id = post_response$id,
    name = "UpdatedName",
    status = "sold",
    photoUrls = list("https://example.com/photo.jpg")
  )

  update_response <- client$.fetch(
    path = "/pet",
    body = updated_data,
    method = "put",
    content = "body"
  )

  expect_type(update_response, "list")
  expect_equal(update_response$id, post_response$id)
  expect_equal(update_response$name, "UpdatedName")
  expect_equal(update_response$status, "sold")
})
