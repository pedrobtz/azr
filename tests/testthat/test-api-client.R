test_that("api_client can be initialized with basic settings", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2",
    timeout = 30L,
    max_tries = 3L
  )

  expect_true(R6::is.R6(client))
  expect_true(inherits(client, "api_client"))
  expect_equal(client$.host_url, "https://petstore.swagger.io/v2")
  expect_equal(client$.options$timeout, 30L)
  expect_equal(client$.options$max_tries, 3L)
})

test_that("api_client can POST a new pet", {
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
      req_data = pet_data,
      req_method = "post",
      content = "body"
    )

    expect_type(response, "list")
    expect_equal(response$name, "TestDog")
    expect_equal(response$status, "available")
    expect_true(!is.null(response$id))
  })
})

test_that("api_client can GET a pet by ID", {
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
      req_data = pet_data,
      req_method = "post",
      content = "body"
    )

    # GET the pet by ID
    get_response <- client$.fetch(
      path = "/pet/{petId}",
      petId = post_response$id,
      req_method = "get",
      content = "body"
    )

    expect_type(get_response, "list")
    expect_equal(get_response$id, post_response$id)
    expect_equal(get_response$name, "GetTestDog")
    expect_equal(get_response$status, "available")
  })
})

test_that("api_client can GET pets by status", {
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
      req_data = pet_data,
      req_method = "post",
      content = "body"
    )

    # GET pets with 'pending' status using query parameters
    response <- client$.fetch(
      path = "/pet/findByStatus",
      req_data = list(status = "pending"),
      req_method = "get",
      content = "body"
    )

    expect_type(response, "list")
    expect_true(length(response) > 0)

    # Verify we can find our created pet
    expect_true(pet_id %in% response$id)

    # Verify all returned pets have pending status
    expect_true(all("pending" == response$status))
  })
})

test_that("api_client can PUT to update a pet", {
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
      req_data = pet_data,
      req_method = "post",
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
      req_data = updated_data,
      req_method = "put",
      content = "body"
    )

    expect_type(update_response, "list")
    expect_equal(update_response$id, post_response$id)
    expect_equal(update_response$name, "UpdatedName")
    expect_equal(update_response$status, "sold")
  })
})

test_that("api_client returns response headers when requested", {
  vcr::use_cassette("api-client-headers", {
    client <- api_client$new(
      host_url = "https://petstore.swagger.io/v2"
    )

    headers <- client$.fetch(
      path = "/pet/findByStatus",
      req_data = list(status = "available"),
      req_method = "get",
      content = "headers"
    )

    expect_type(headers, "list")
    expect_true(length(headers) > 0)
    expect_true("content-type" %in% names(headers))
  })
})

test_that("api_client returns full response object when requested", {
  vcr::use_cassette("api-client-response", {
    client <- api_client$new(
      host_url = "https://petstore.swagger.io/v2"
    )

    response <- client$.fetch(
      path = "/pet/findByStatus",
      req_data = list(status = "available"),
      req_method = "get",
      content = "response"
    )

    expect_s3_class(response, "httr2_response")
    expect_true(!is.null(response$status_code))
    expect_equal(response$status_code, 200)
  })
})

test_that("api_client can build request without performing it", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  req <- client$.fetch(
    path = "/pet/{petId}",
    petId = 123,
    req_method = "get",
    content = "request"
  )

  expect_s3_class(req, "httr2_request")
  expect_true(grepl("/pet/123", req$url))
  expect_equal(req$method, "GET")
})

test_that("api_client handles path interpolation correctly", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  pet_id <- 12345
  req <- client$.fetch(
    path = "/pet/{petId}",
    petId = pet_id,
    req_method = "get",
    content = "request"
  )

  expect_true(grepl("/pet/12345", req$url))
})

test_that("api_client DELETE method works", {
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
      req_data = pet_data,
      req_method = "post"
    )

    # Delete the pet
    delete_response <- client$.fetch(
      path = "/pet/{petId}",
      petId = post_response$id,
      req_method = "delete",
      content = "response"
    )

    expect_s3_class(delete_response, "httr2_response")
    expect_equal(delete_response$status_code, 200)
  })
})
