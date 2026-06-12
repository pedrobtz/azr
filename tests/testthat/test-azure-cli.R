test_that("AzureCLICredential can be initialized", {
  testthat::local_mocked_bindings(az_cli_is_login = function(...) TRUE)
  cred <- AzureCLICredential$new()

  expect_s3_class(cred, "AzureCLICredential")
  expect_s3_class(cred, "Credential")
  expect_s3_class(cred, "R6")
})

test_that("AzureCLICredential initialization with custom parameters", {
  testthat::local_mocked_bindings(az_cli_is_login = function(...) TRUE)
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
  testthat::local_mocked_bindings(az_cli_is_login = function(...) TRUE)
  cred <- AzureCLICredential$new()

  expect_false(cred$is_interactive())
})

test_that("AzureCLICredential$get_token fails when not logged in to Azure CLI", {
  testthat::local_mocked_bindings(az_cli_is_login = function(...) FALSE)
  cred <- AzureCLICredential$new()

  expect_error(
    cred$get_token(),
    "User is not logged in to Azure CLI",
    class = "azr_cli_not_logged_in"
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
