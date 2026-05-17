test_that("client_secret type returns correct global keys", {
  conf <- azure_spark_storage_conf(
    type = "client_secret",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret"
  )

  expect_equal(conf[["fs.azure.account.auth.type"]], "OAuth")
  expect_equal(
    conf[["fs.azure.account.oauth.provider.type"]],
    "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
  )
  expect_equal(conf[["fs.azure.account.oauth2.client.id"]], "my-client")
  expect_equal(conf[["fs.azure.account.oauth2.client.secret"]], "my-secret")
  expect_equal(
    conf[["fs.azure.account.oauth2.client.endpoint"]],
    "https://login.microsoftonline.com/my-tenant/oauth2/token"
  )
})

test_that("client_secret type scopes keys to specific storage account", {
  conf <- azure_spark_storage_conf(
    type = "client_secret",
    storage = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret"
  )

  expect_equal(
    conf[["fs.azure.account.auth.type.mystorageaccount.dfs.core.windows.net"]],
    "OAuth"
  )
  expect_equal(
    conf[["fs.azure.account.oauth2.client.id.mystorageaccount.dfs.core.windows.net"]],
    "my-client"
  )
  expect_equal(
    conf[["fs.azure.account.oauth2.client.secret.mystorageaccount.dfs.core.windows.net"]],
    "my-secret"
  )
  expect_null(conf[["fs.azure.account.auth.type"]])
})

test_that("refresh_token type returns correct global keys", {
  conf <- azure_spark_storage_conf(
    type = "refresh_token",
    tenant_id = "my-tenant",
    client_id = "my-client",
    refresh_token = "my-refresh-token"
  )

  expect_equal(conf[["fs.azure.account.auth.type"]], "OAuth")
  expect_equal(
    conf[["fs.azure.account.oauth.provider.type"]],
    "org.apache.hadoop.fs.azurebfs.oauth2.RefreshTokenBasedTokenProvider"
  )
  expect_equal(conf[["fs.azure.account.oauth2.client.id"]], "my-client")
  expect_equal(conf[["fs.azure.account.oauth2.refresh.token"]], "my-refresh-token")
  expect_equal(
    conf[["fs.azure.account.oauth2.client.endpoint"]],
    "https://login.microsoftonline.com/my-tenant/oauth2/token"
  )
})

test_that("refresh_token type scopes keys to specific storage account", {
  conf <- azure_spark_storage_conf(
    type = "refresh_token",
    storage = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    refresh_token = "my-refresh-token"
  )

  expect_equal(
    conf[["fs.azure.account.oauth2.refresh.token.mystorageaccount.dfs.core.windows.net"]],
    "my-refresh-token"
  )
})

test_that("workload_identity type returns correct global keys", {
  conf <- azure_spark_storage_conf(
    type = "workload_identity",
    tenant_id = "my-tenant",
    client_id = "my-client",
    token_file = "/var/run/secrets/azure/tokens/azure-identity-token",
    oauth_host = "login.microsoftonline.com"
  )

  expect_equal(conf[["fs.azure.account.auth.type"]], "OAuth")
  expect_equal(
    conf[["fs.azure.account.oauth.provider.type"]],
    "org.apache.hadoop.fs.azurebfs.oauth2.WorkloadIdentityTokenProvider"
  )
  expect_equal(conf[["fs.azure.account.oauth2.client.id"]], "my-client")
  expect_equal(conf[["fs.azure.account.oauth2.msi.tenant"]], "my-tenant")
  expect_equal(
    conf[["fs.azure.account.oauth2.token.file"]],
    "/var/run/secrets/azure/tokens/azure-identity-token"
  )
  expect_equal(conf[["fs.azure.account.oauth2.msi.authority"]], "login.microsoftonline.com")
})

test_that("workload_identity type scopes keys to specific storage account", {
  conf <- azure_spark_storage_conf(
    type = "workload_identity",
    storage = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    token_file = "/var/run/secrets/azure/tokens/azure-identity-token",
    oauth_host = "login.microsoftonline.com"
  )

  expect_equal(
    conf[["fs.azure.account.auth.type.mystorageaccount.dfs.core.windows.net"]],
    "OAuth"
  )
  expect_equal(
    conf[["fs.azure.account.oauth2.token.file.mystorageaccount.dfs.core.windows.net"]],
    "/var/run/secrets/azure/tokens/azure-identity-token"
  )
})

test_that("workload_identity errors when token_file is missing", {
  expect_error(
    azure_spark_storage_conf(
      type = "workload_identity",
      tenant_id = "my-tenant",
      client_id = "my-client",
      token_file = NULL
    ),
    class = "rlang_error"
  )
})

test_that("errors when client_secret is missing for client_secret type", {
  expect_error(
    azure_spark_storage_conf(
      type = "client_secret",
      tenant_id = "my-tenant",
      client_id = "my-client",
      client_secret = NULL
    ),
    class = "rlang_error"
  )
})

test_that("errors when refresh_token is missing for refresh_token type", {
  expect_error(
    azure_spark_storage_conf(
      type = "refresh_token",
      tenant_id = "my-tenant",
      client_id = "my-client",
      refresh_token = NULL
    ),
    class = "rlang_error"
  )
})

test_that("errors on invalid storage argument", {
  expect_error(
    azure_spark_storage_conf(
      type = "workload_identity",
      storage = "",
      tenant_id = "my-tenant",
      client_id = "my-client"
    ),
    class = "rlang_error"
  )
})

test_that("all three types return the correct number of keys", {
  cs <- azure_spark_storage_conf(
    type = "client_secret",
    tenant_id = "t",
    client_id = "c",
    client_secret = "s"
  )
  rt <- azure_spark_storage_conf(
    type = "refresh_token",
    tenant_id = "t",
    client_id = "c",
    refresh_token = "r"
  )
  wi <- azure_spark_storage_conf(
    type = "workload_identity",
    tenant_id = "t",
    client_id = "c",
    token_file = "/tmp/token",
    oauth_host = "login.microsoftonline.com"
  )

  expect_length(cs, 5L)
  expect_length(rt, 5L)
  expect_length(wi, 6L)
})
