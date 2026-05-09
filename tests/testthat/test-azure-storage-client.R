test_that("api_storage_client uses default DFS endpoint suffix", {
  client <- api_storage_client$new(
    storageaccount = "mystorageaccount",
    filesystem = "myfilesystem"
  )

  expect_equal(
    client$.host_url,
    "https://mystorageaccount.dfs.core.windows.net"
  )
})

test_that("api_storage_client uses default Azure Storage scope", {
  client <- api_storage_client$new(
    storageaccount = "mystorageaccount",
    filesystem = "myfilesystem"
  )

  expect_equal(client$.provider$.scope, default_azure_scope("azure_storage"))
})

test_that("api_storage_client accepts full custom scope", {
  client <- api_storage_client$new(
    storageaccount = "mystorageaccount",
    filesystem = "myfilesystem",
    scope = "https://example.storage/.default"
  )

  expect_equal(client$.provider$.scope, "https://example.storage/.default")
})

test_that("api_storage_client accepts custom storage endpoint suffix", {
  client <- api_storage_client$new(
    storageaccount = "mystorageaccount",
    filesystem = "myfilesystem",
    endpoint_suffix = "dfs.core.usgovcloudapi.net"
  )

  expect_equal(
    client$.host_url,
    "https://mystorageaccount.dfs.core.usgovcloudapi.net"
  )
})

test_that("storage_host_url normalizes custom storage endpoint suffix", {
  expect_equal(
    storage_host_url(
      storageaccount = "mystorageaccount",
      endpoint_suffix = "https://.dfs.core.usgovcloudapi.net/"
    ),
    "https://mystorageaccount.dfs.core.usgovcloudapi.net"
  )
})

test_that("storage_host_url rejects empty normalized endpoint suffix", {
  expect_error(
    storage_host_url(
      storageaccount = "mystorageaccount",
      endpoint_suffix = "https://..."
    ),
    "endpoint_suffix"
  )
})

test_that("api_storage_client uses normalized custom storage endpoint suffix", {
  client <- api_storage_client$new(
    storageaccount = "mystorageaccount",
    filesystem = "myfilesystem",
    endpoint_suffix = "https://.dfs.core.usgovcloudapi.net/"
  )

  expect_equal(
    client$.host_url,
    "https://mystorageaccount.dfs.core.usgovcloudapi.net"
  )
})

test_that("azr_storage_client passes custom storage endpoint suffix", {
  client <- azr_storage_client(
    storageaccount = "mystorageaccount",
    filesystem = "myfilesystem",
    endpoint_suffix = "dfs.core.usgovcloudapi.net"
  )

  expect_equal(
    client$.host_url,
    "https://mystorageaccount.dfs.core.usgovcloudapi.net"
  )
})

test_that("api_storage_client uses supplied credential provider", {
  provider <- ClientSecretCredential$new(
    tenant_id = "common",
    client_id = "test-client",
    client_secret = "test-secret"
  )

  client <- api_storage_client$new(
    storageaccount = "mystorageaccount",
    filesystem = "myfilesystem",
    provider = provider,
    chain = "not-a-chain"
  )

  expect_identical(client$.provider, provider)
})

test_that("azr_storage_client passes supplied credential provider", {
  provider <- ClientSecretCredential$new(
    tenant_id = "common",
    client_id = "test-client",
    client_secret = "test-secret"
  )

  client <- azr_storage_client(
    storageaccount = "mystorageaccount",
    filesystem = "myfilesystem",
    provider = provider,
    chain = "not-a-chain"
  )

  expect_identical(client$.provider, provider)
})

test_that("api_storage_client validates supplied credential provider", {
  expect_error(
    api_storage_client$new(
      storageaccount = "mystorageaccount",
      filesystem = "myfilesystem",
      provider = list()
    ),
    "provider"
  )
})
