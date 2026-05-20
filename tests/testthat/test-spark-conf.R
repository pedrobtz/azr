test_that("client_secret type returns correct global keys", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret"
  )

  expect_equal(conf[["spark.hadoop.fs.azure.account.auth.type"]], "OAuth")
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth.provider.type"]],
    "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.client.id"]],
    "my-client"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.client.secret"]],
    "my-secret"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.client.endpoint"]],
    "https://login.microsoftonline.com/my-tenant/oauth2/v2.0/token"
  )
})

test_that("client_secret type scopes keys to specific storage account", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    storage_account = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret"
  )

  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.auth.type.mystorageaccount.dfs.core.windows.net"
    ]],
    "OAuth"
  )
  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.oauth2.client.id.mystorageaccount.dfs.core.windows.net"
    ]],
    "my-client"
  )
  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.oauth2.client.secret.mystorageaccount.dfs.core.windows.net"
    ]],
    "my-secret"
  )
  expect_null(conf[["spark.hadoop.fs.azure.account.auth.type"]])
})

test_that("refresh_token type uses refresh.token.endpoint key, not client.endpoint", {
  conf <- azure_spark_storage_conf(
    auth_type = "refresh_token",
    tenant_id = "my-tenant",
    client_id = "my-client",
    refresh_token = "my-refresh-token"
  )

  expect_equal(conf[["spark.hadoop.fs.azure.account.auth.type"]], "OAuth")
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth.provider.type"]],
    "org.apache.hadoop.fs.azurebfs.oauth2.RefreshTokenBasedTokenProvider"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.client.id"]],
    "my-client"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.refresh.token"]],
    "my-refresh-token"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.refresh.token.endpoint"]],
    "https://login.microsoftonline.com/my-tenant/oauth2/v2.0/token"
  )
  # client.endpoint is silently ignored by RefreshTokenBasedTokenProvider and
  # must not be emitted.
  expect_null(conf[["spark.hadoop.fs.azure.account.oauth2.client.endpoint"]])
})

test_that("refresh_token type scopes keys to specific storage account", {
  conf <- azure_spark_storage_conf(
    auth_type = "refresh_token",
    storage_account = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    refresh_token = "my-refresh-token"
  )

  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.oauth2.refresh.token.mystorageaccount.dfs.core.windows.net"
    ]],
    "my-refresh-token"
  )
})

test_that("workload_identity type returns correct global keys", {
  conf <- azure_spark_storage_conf(
    auth_type = "workload_identity",
    tenant_id = "my-tenant",
    client_id = "my-client",
    token_file = "/var/run/secrets/azure/tokens/azure-identity-token",
    authority_host = "login.microsoftonline.com"
  )

  expect_equal(conf[["spark.hadoop.fs.azure.account.auth.type"]], "OAuth")
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth.provider.type"]],
    "org.apache.hadoop.fs.azurebfs.oauth2.WorkloadIdentityTokenProvider"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.client.id"]],
    "my-client"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.msi.tenant"]],
    "my-tenant"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.token.file"]],
    "/var/run/secrets/azure/tokens/azure-identity-token"
  )
  # msi.authority must end with `/` — Hadoop literal-concatenates
  # `authority + tenantId + "/oauth2/v2.0/token"`.
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.msi.authority"]],
    "https://login.microsoftonline.com/"
  )
})

test_that("workload_identity type scopes keys to specific storage account", {
  conf <- azure_spark_storage_conf(
    auth_type = "workload_identity",
    storage_account = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    token_file = "/var/run/secrets/azure/tokens/azure-identity-token",
    authority_host = "login.microsoftonline.com"
  )

  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.auth.type.mystorageaccount.dfs.core.windows.net"
    ]],
    "OAuth"
  )
  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.oauth2.token.file.mystorageaccount.dfs.core.windows.net"
    ]],
    "/var/run/secrets/azure/tokens/azure-identity-token"
  )
})

test_that("managed_identity type returns correct keys", {
  conf <- azure_spark_storage_conf(
    auth_type = "managed_identity",
    tenant_id = "my-tenant",
    client_id = "my-uami-client-id"
  )

  expect_equal(conf[["spark.hadoop.fs.azure.account.auth.type"]], "OAuth")
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth.provider.type"]],
    "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.client.id"]],
    "my-uami-client-id"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.msi.tenant"]],
    "my-tenant"
  )
  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.msi.authority"]],
    "https://login.microsoftonline.com/"
  )
})

test_that("shared_key type emits SharedKey auth type and account key", {
  conf <- azure_spark_storage_conf(
    auth_type = "shared_key",
    storage_account = "mystorageaccount",
    account_key = "AAAA=="
  )

  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.auth.type.mystorageaccount.dfs.core.windows.net"
    ]],
    "SharedKey"
  )
  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.key.mystorageaccount.dfs.core.windows.net"
    ]],
    "AAAA=="
  )
})

test_that("shared_key requires both storage_account and account_key", {
  expect_error(
    azure_spark_storage_conf(
      auth_type = "shared_key",
      account_key = "AAAA=="
    ),
    class = "rlang_error"
  )
  expect_error(
    azure_spark_storage_conf(
      auth_type = "shared_key",
      storage_account = "mystorageaccount"
    ),
    class = "rlang_error"
  )
})

test_that("workload_identity errors when token_file is missing", {
  expect_error(
    azure_spark_storage_conf(
      auth_type = "workload_identity",
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
      auth_type = "client_secret",
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
      auth_type = "refresh_token",
      tenant_id = "my-tenant",
      client_id = "my-client",
      refresh_token = NULL
    ),
    class = "rlang_error"
  )
})

test_that("errors on invalid storage_account argument", {
  expect_error(
    azure_spark_storage_conf(
      auth_type = "workload_identity",
      storage_account = "",
      tenant_id = "my-tenant",
      client_id = "my-client"
    ),
    class = "rlang_error"
  )
})

test_that("US Government cloud uses gov token endpoint and gov storage suffix", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    storage_account = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret",
    authority_host = "login.microsoftonline.us"
  )

  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.auth.type.mystorageaccount.dfs.core.usgovcloudapi.net"
    ]],
    "OAuth"
  )
  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.oauth2.client.endpoint.mystorageaccount.dfs.core.usgovcloudapi.net"
    ]],
    "https://login.microsoftonline.us/my-tenant/oauth2/v2.0/token"
  )
})

test_that("China cloud uses china token endpoint and china storage suffix", {
  conf <- azure_spark_storage_conf(
    auth_type = "refresh_token",
    storage_account = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    refresh_token = "my-refresh-token",
    authority_host = "login.chinacloudapi.cn"
  )

  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.oauth2.refresh.token.endpoint.mystorageaccount.dfs.core.chinacloudapi.cn"
    ]],
    "https://login.chinacloudapi.cn/my-tenant/oauth2/v2.0/token"
  )
})

test_that("fully qualified storage_account is used verbatim", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    storage_account = "myacct.dfs.core.usgovcloudapi.net",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret"
  )

  expect_equal(
    conf[[
      "spark.hadoop.fs.azure.account.auth.type.myacct.dfs.core.usgovcloudapi.net"
    ]],
    "OAuth"
  )
})

test_that("authority_host with https:// scheme is normalized correctly", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret",
    authority_host = "https://login.microsoftonline.com/"
  )

  expect_equal(
    conf[["spark.hadoop.fs.azure.account.oauth2.client.endpoint"]],
    "https://login.microsoftonline.com/my-tenant/oauth2/v2.0/token"
  )
})

test_that("prefix = NULL returns raw fs.azure.* keys", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret",
    prefix = NULL
  )

  expect_equal(conf[["fs.azure.account.auth.type"]], "OAuth")
  expect_equal(conf[["fs.azure.account.oauth2.client.id"]], "my-client")
  expect_null(conf[["spark.hadoop.fs.azure.account.auth.type"]])
})

test_that("custom prefix is honored and trailing dots are stripped", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    storage_account = "mystorageaccount",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret",
    prefix = "my.custom."
  )

  expect_equal(
    conf[[
      "my.custom.fs.azure.account.auth.type.mystorageaccount.dfs.core.windows.net"
    ]],
    "OAuth"
  )
})

test_that("invalid prefix is rejected", {
  expect_error(
    azure_spark_storage_conf(
      auth_type = "client_secret",
      tenant_id = "t",
      client_id = "c",
      client_secret = "s",
      prefix = ""
    ),
    class = "rlang_error"
  )
  expect_error(
    azure_spark_storage_conf(
      auth_type = "client_secret",
      tenant_id = "t",
      client_id = "c",
      client_secret = "s",
      prefix = 42
    ),
    class = "rlang_error"
  )
})

test_that("all auth types return the correct number of keys", {
  cs <- azure_spark_storage_conf(
    auth_type = "client_secret",
    tenant_id = "t",
    client_id = "c",
    client_secret = "s"
  )
  rt <- azure_spark_storage_conf(
    auth_type = "refresh_token",
    tenant_id = "t",
    client_id = "c",
    refresh_token = "r"
  )
  wi <- azure_spark_storage_conf(
    auth_type = "workload_identity",
    tenant_id = "t",
    client_id = "c",
    token_file = "/tmp/token",
    authority_host = "login.microsoftonline.com"
  )
  mi <- azure_spark_storage_conf(
    auth_type = "managed_identity",
    tenant_id = "t",
    client_id = "c"
  )
  sk <- azure_spark_storage_conf(
    auth_type = "shared_key",
    storage_account = "a",
    account_key = "k"
  )

  expect_length(cs, 5L)
  expect_length(rt, 5L)
  expect_length(wi, 6L)
  expect_length(mi, 5L)
  expect_length(sk, 2L)
})

# azure_spark_config class and print ----

test_that("azure_spark_storage_conf returns azure_spark_config", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    tenant_id = "t",
    client_id = "c",
    client_secret = "s"
  )
  expect_s3_class(conf, "azure_spark_config")
})

test_that("print.azure_spark_config redacts client.secret", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    tenant_id = "t",
    client_id = "c",
    client_secret = "super-secret"
  )
  output <- capture.output(print(conf))
  expect_false(any(grepl("super-secret", output)))
  expect_true(any(grepl("REDACTED", output)))
})

test_that("print.azure_spark_config redacts refresh.token but not endpoint", {
  conf <- azure_spark_storage_conf(
    auth_type = "refresh_token",
    tenant_id = "t",
    client_id = "c",
    refresh_token = "my-refresh-token"
  )
  output <- capture.output(print(conf))
  expect_false(any(grepl("my-refresh-token", output)))
  expect_true(any(grepl("REDACTED", output)))
  # endpoint URL should still be visible
  expect_true(any(grepl("microsoftonline", output)))
})

test_that("print.azure_spark_config redacts account key", {
  conf <- azure_spark_storage_conf(
    auth_type = "shared_key",
    storage_account = "myaccount",
    account_key = "SUPER_SECRET_KEY"
  )
  output <- capture.output(print(conf))
  expect_false(any(grepl("SUPER_SECRET_KEY", output)))
  expect_true(any(grepl("REDACTED", output)))
})

test_that("print.azure_spark_config does not redact non-sensitive keys", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "s"
  )
  output <- capture.output(print(conf))
  expect_true(any(grepl("my-client", output)))
  expect_true(any(grepl("OAuth", output)))
})

test_that("print.azure_spark_config returns x invisibly", {
  conf <- azure_spark_storage_conf(
    auth_type = "client_secret",
    tenant_id = "t",
    client_id = "c",
    client_secret = "s"
  )
  result <- withVisible(print(conf))
  expect_false(result$visible)
  expect_identical(result$value, conf)
})
