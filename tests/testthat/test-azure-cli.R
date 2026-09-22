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


test_that("AzureCLICredential validates tenant_id at construction", {
  expect_error(
    AzureCLICredential$new(tenant_id = "invalid!tenant"),
    "not valid"
  )
})


test_that("AzureCLICredential reports the Azure CLI client, not AZURE_CLIENT_ID", {
  withr::local_envvar(AZURE_CLIENT_ID = "some-other-app")

  cred <- AzureCLICredential$new(scope = "https://management.azure.com/.default")

  expect_equal(cred$.client_id, default_azure_cli_client_id())
  expect_false(identical(cred$.client_id, "some-other-app"))
})


cli_account <- function(type, name = "an-account") {
  list(user = list(name = name, type = type), tenantId = "t", id = "sub")
}

test_that("UserAzureCLICredential accepts a user sign-in", {
  local_mocked_bindings(
    az_cli_account_show = function(...) cli_account("user", "jane@contoso.com"),
    az_cli_get_token = function(...) httr2::oauth_token("a-user-token")
  )

  cred <- UserAzureCLICredential$new(scope = "https://management.azure.com/.default")

  expect_equal(cred$get_token()$access_token, "a-user-token")
})

test_that("UserAzureCLICredential rejects a service principal sign-in", {
  local_mocked_bindings(
    az_cli_account_show = function(...) cli_account("servicePrincipal", "an-app-id"),
    az_cli_get_token = function(...) httr2::oauth_token("an-app-token")
  )

  cred <- UserAzureCLICredential$new(scope = "https://management.azure.com/.default")

  err <- expect_error(cred$get_token(), class = "azr_cli_not_user_account")
  expect_match(conditionMessage(err), "servicePrincipal")
  expect_match(conditionMessage(err), "an-app-id")
})

test_that("AzureCLICredential still accepts a service principal sign-in", {
  local_mocked_bindings(
    az_cli_account_show = function(...) cli_account("servicePrincipal", "an-app-id"),
    az_cli_get_token = function(...) httr2::oauth_token("an-app-token")
  )

  cred <- AzureCLICredential$new(scope = "https://management.azure.com/.default")

  # authenticating as a service principal through the CLI stays a valid way to
  # use get_token(); only get_user_token() insists on a person
  expect_equal(cred$get_token()$access_token, "an-app-token")
})
