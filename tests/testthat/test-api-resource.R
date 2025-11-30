test_that("api_resource can be initialized with client and endpoint", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  resource <- api_resource$new(
    client = client,
    endpoint = "store"
  )

  expect_true(R6::is.R6(resource))
  expect_true(inherits(resource, "api_resource"))
  expect_true(R6::is.R6(resource$.client))
  expect_true(inherits(resource$.client, "api_client"))
})

test_that("api_resource validates client parameter", {
  expect_error(
    api_resource$new(client = NULL, endpoint = "store"),
    "client.*must not.*NULL"
  )

  expect_error(
    api_resource$new(client = "not_an_r6", endpoint = "store"),
    "client.*must be an R6 object"
  )

  expect_error(
    api_resource$new(client = list(), endpoint = "store"),
    "client.*must be an R6 object"
  )
})

test_that("api_resource validates endpoint parameter", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  expect_error(
    api_resource$new(client = client, endpoint = NULL),
    "endpoint.*must not.*NULL"
  )

  expect_error(
    api_resource$new(client = client, endpoint = 123),
    "endpoint.*must be a character string"
  )

  expect_error(
    api_resource$new(client = client, endpoint = c("a", "b")),
    "endpoint.*must be a single character string"
  )

  expect_error(
    api_resource$new(client = client, endpoint = ""),
    "endpoint.*must not be an empty string"
  )
})

test_that("api_store_resource can create an order", {
  vcr::use_cassette("api-resource-create-order", {
    client <- api_client$new(
      host_url = "https://petstore.swagger.io/v2"
    )

    store_resource <- api_store_resource$new(
      client = client,
      endpoint = "store"
    )

    order_data <- list(
      id = 12345L,
      petId = 1L,
      quantity = 1L,
      shipDate = "2024-01-15T10:00:00.000Z",
      status = "placed",
      complete = FALSE
    )

    response <- store_resource$create_order(order_data)

    expect_type(response, "list")
    expect_true(!is.null(response$id))
    expect_equal(response$status, "placed")
    expect_equal(response$quantity, 1L)
  })
})

test_that("api_store_resource can get an order by ID", {
  vcr::use_cassette("api-resource-get-order", {
    client <- api_client$new(
      host_url = "https://petstore.swagger.io/v2"
    )

    store_resource <- api_store_resource$new(
      client = client,
      endpoint = "store"
    )

    # First create an order
    order_data <- list(
      id = 67890L,
      petId = 1L,
      quantity = 2L,
      shipDate = "2024-01-15T11:00:00.000Z",
      status = "placed",
      complete = FALSE
    )

    created_order <- store_resource$create_order(order_data)

    # Get the order by ID
    retrieved_order <- store_resource$get_order(created_order$id)

    expect_type(retrieved_order, "list")
    expect_equal(retrieved_order$id, created_order$id)
    expect_equal(retrieved_order$petId, 1L)
    expect_equal(retrieved_order$quantity, 2L)
    expect_equal(retrieved_order$status, "placed")
  })
})

test_that("api_resource clones the client to avoid modifying original", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  original_url <- client$.base_req$url

  resource <- api_resource$new(
    client = client,
    endpoint = "store"
  )

  # Original client should be unchanged
  expect_equal(client$.base_req$url, original_url)

  # Resource client should have modified URL
  expect_true(grepl("store", resource$.client$.base_req$url))
})

test_that("api_store_resource inherits from api_resource", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  store_resource <- api_store_resource$new(
    client = client,
    endpoint = "store"
  )

  expect_true(R6::is.R6(store_resource))
  expect_true(inherits(store_resource, "api_resource"))
  expect_true(inherits(store_resource, "api_store_resource"))
})

test_that("api_resource endpoint is correctly appended to requests", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  store_resource <- api_store_resource$new(
    client = client,
    endpoint = "store"
  )

  # Build a request without executing it
  req <- store_resource$.client$.fetch(
    path = "/order/1",
    req_method = "get",
    content = "request"
  )

  expect_s3_class(req, "httr2_request")
  expect_true(grepl("/store/order/1", req$url))
})
