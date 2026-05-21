#' Azure Default Client Configuration
#'
#' @description
#' Default client ID and tenant ID used for Azure authentication when not
#' explicitly provided. The client ID is Microsoft's public Azure CLI client ID.
#'
#' @keywords internal
azure_client <- list(
  tenant_id = "common",
  client_id = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
)

#' Azure Authority Host URLs
#'
#' @description
#' Login endpoint URLs for different Azure cloud environments.
#'
#' @keywords internal
azure_authority_hosts <- list(
  azure_china = "login.chinacloudapi.cn",
  azure_government = "login.microsoftonline.us",
  azure_public_cloud = "login.microsoftonline.com"
)

#' Azure Service Definitions
#'
#' @description
#' Per-service metadata for common Azure services. Each entry holds the OAuth
#' resource `host` (used to derive the `/.default` scope) and any additional
#' data-plane endpoints where requests are sent. For most services the
#' data-plane host is the same as the OAuth resource host; Azure Storage is the
#' exception (resource host `storage.azure.com`, data-plane host
#' `*.dfs.core.windows.net`).
#'
#' @keywords internal
azure_services <- list(
  azure_arm = list(host = "management.azure.com"),
  azure_graph = list(host = "graph.microsoft.com"),
  azure_storage = list(
    host = "storage.azure.com",
    dfs = "dfs.core.windows.net"
  ),
  azure_key_vault = list(host = "vault.azure.net"),
  azure_openai = list(host = "cognitiveservices.azure.com"),
  azure_log_analytics = list(host = "api.loganalytics.io"),
  azure_app_insights = list(host = "api.applicationinsights.io"),
  azure_databricks = list(host = "databricks.azure.com"),
  azure_sql = list(host = "database.windows.net"),
  azure_service_bus = list(host = "servicebus.azure.net")
)

#' Azure Environment Variable Names
#'
#' @description
#' Standard environment variable names used for Azure credential discovery.
#'
#' @keywords internal
environment_variables <- list(
  azure_client_id = "AZURE_CLIENT_ID",
  azure_client_secret = "AZURE_CLIENT_SECRET",
  azure_tenant_id = "AZURE_TENANT_ID",
  azure_authority_host = "AZURE_AUTHORITY_HOST",
  azure_refresh_token = "AZURE_REFRESH_TOKEN",
  client_secret_vars = c(
    "AZURE_CLIENT_ID",
    "AZURE_CLIENT_SECRET",
    "AZURE_TENANT_ID"
  ),
  cert_vars = c(
    "AZURE_CLIENT_ID",
    "AZURE_CLIENT_CERTIFICATE_PATH",
    "AZURE_TENANT_ID"
  ),
  azure_username = "AZURE_USERNAME",
  azure_password = "AZURE_PASSWORD",
  username_password_vars = c(
    "AZURE_CLIENT_ID",
    "AZURE_USERNAME",
    "AZURE_PASSWORD"
  ),
  azure_federated_token_file = "AZURE_FEDERATED_TOKEN_FILE"
)
