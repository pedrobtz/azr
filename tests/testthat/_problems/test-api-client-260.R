# Extracted from test-api-client.R:260

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-client-delete", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  # Create a pet to delete
  pet_id <- 10005L
  pet_data <- list(
    id = pet_id,
    name = "ToBeDeleted",
    status = "available",
    photoUrls = list("https://example.com/photo.jpg")
  )

  post_response <- client$.fetch(
    path = "/pet",
    body = pet_data,
    method = "post"
  )

  # Delete the pet
  delete_response <- client$.fetch(
    path = "/pet/{petId}",
    petId = post_response$id,
    method = "delete",
    content = "response"
  )

  expect_s3_class(delete_response, "httr2_response")
  expect_equal(delete_response$status_code, 200)
})
