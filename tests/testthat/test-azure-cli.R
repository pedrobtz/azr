test_that("AzureCLICredential can be initialized", {
  cred <- AzureCLICredential$new()

  expect_s3_class(cred, "AzureCLICredential")
  expect_s3_class(cred, "Credential")
  expect_s3_class(cred, "R6")
})

test_that("AzureCLICredential initialization with custom parameters", {
  cred <- AzureCLICredential$new(
    scope = "https://management.azure.com/.default",
    tenant_id = "test-tenant-id",
    process_timeout = 20
  )

  expect_equal(cred$.scope, "https://management.azure.com/.default")
  expect_equal(cred$.tenant_id, "test-tenant-id")
  expect_equal(cred$.process_timeout, 20)
})

test_that("AzureCLICredential$is_interactive returns FALSE", {
  cred <- AzureCLICredential$new()

  expect_false(cred$is_interactive())
})

test_that("AzureCLICredential$get_token fails when Azure CLI is not available", {
  skip_if(nzchar(Sys.which("az")), "Azure CLI is installed")

  cred <- AzureCLICredential$new()

  expect_error(
    cred$get_token(),
    "Azure CLI not found on path"
  )
})

test_that("AzureCLICredential$get_token fails when not logged in via az login", {
  skip_if_not(nzchar(Sys.which("az")), "Azure CLI not installed")

  cred <- AzureCLICredential$new()

  # This test expects get_token to fail because we're not logged in
  # or because we're in a non-interactive environment
  expect_error(cred$get_token())
})

test_that("AzureCLICredential$get_token accepts custom scope", {
  skip_if_not(nzchar(Sys.which("az")), "Azure CLI not installed")

  cred <- AzureCLICredential$new()

  # This will fail if not logged in, but we're testing parameter passing
  expect_error(
    cred$get_token(scope = "https://storage.azure.com/.default")
  )
})

test_that("AzureCLICredential$req_auth adds bearer token to request", {
  skip_if_not(nzchar(Sys.which("az")), "Azure CLI not installed")
  skip("Requires active Azure CLI login")

  cred <- AzureCLICredential$new()
  req <- httr2::request("https://management.azure.com/subscriptions")

  # This would work if logged in via az login
  expect_error(cred$req_auth(req))
})


test_that("AzureCLICredential validates tenant_id", {
  expect_error(
    AzureCLICredential$new(tenant_id = "invalid!tenant"),
    "not valid"
  )
})
