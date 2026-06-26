# Manual tests for WorkloadIdentityCredential
#
# These tests are NOT run by `devtools::test()` or CI/CD because they live
# outside `tests/testthat/`. They are intended to be sourced manually from
# an environment where Azure Workload Identity is configured — typically a
# Kubernetes/AKS pod with a federated token mounted at
# `AZURE_FEDERATED_TOKEN_FILE` and `AZURE_TENANT_ID` / `AZURE_CLIENT_ID` set
# to the federated app registration.
#
# See `tests/manual/README.md` for how to run.

library(testthat)
library(azr)

test_that("WorkloadIdentityCredential acquires a token with the default (federated) client_id", {
  cred <- WorkloadIdentityCredential$new()

  token <- cred$get_token()

  expect_s3_class(token, "httr2_token")
  expect_true(nzchar(token$access_token))
})

test_that("WorkloadIdentityCredential fails when client_id is the Azure CLI public client", {
  cred <- WorkloadIdentityCredential$new(
    client_id = default_azure_cli_client_id()
  )

  expect_error(
    cred$get_token(),
    class = "azr_workload_identity_token_error"
  )
})
