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

#' Common Azure OAuth Scopes
#'
#' @description
#' Predefined OAuth scopes for common Azure services.
#'
#' @keywords internal
azure_scopes <- list(
  azure_arm = "https://management.azure.com/.default",
  azure_graph = "https://graph.microsoft.com/.default",
  azure_storage = "https://storage.azure.com/.default",
  azure_key_vault = "https://vault.azure.net/.default"
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
  client_secret_vars = c("AZURE_CLIENT_ID", "AZURE_CLIENT_SECRET", "AZURE_TENANT_ID"),
  cert_vars = c("AZURE_CLIENT_ID", "AZURE_CLIENT_CERTIFICATE_PATH", "AZURE_TENANT_ID"),
  azure_username = "AZURE_USERNAME",
  azure_password = "AZURE_PASSWORD",
  username_password_vars = c("AZURE_CLIENT_ID", "AZURE_USERNAME", "AZURE_PASSWORD")
)
