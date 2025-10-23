Credential <- R6::R6Class(
  classname = "Credential",
  public = list(
    .id = NULL,
    .scope = NULL,
    .scope_str = NULL,
    .resource = NULL,
    .client_id = NULL,
    .client_secret = NULL,
    .tenant_id = NULL,
    .use_cache = "disk",
    .cache_key = NULL,
    .oauth_client = NULL,
    .oauth_host = NULL,
    .oauth_endpoint = NULL,
    .oauth_url = NULL,
    .token_url = NULL,
    .redirect_uri = NULL,
    initialize = function(scope = NULL,
                          tenant_id = NULL,
                          client_id = NULL,
                          client_secret = NULL,
                          use_cache = c("disk", "memory"),
                          offline = FALSE,
                          oauth_endpoint = NULL) {
      self$.scope <- scope %||% default_azure_scope(resource = "azure_arm")

      if (isTRUE(offline)) {
        self$.scope <- unique(c(self$.scope, "offline_access"))
      }

      self$.scope_str <- collapse_scope(self$.scope)
      self$.resource <- get_scope_resource(self$.scope)

      self$.client_id <- client_id %|||% default_azure_client_id()
      self$.client_secret <- client_secret %|||% default_azure_client_secret() %|||% NULL

      self$.tenant_id <- tenant_id %||% default_azure_tenant_id()
      self$.use_cache <- rlang::arg_match(use_cache)

      self$.cache_key <- c(self$.client_id, self$.tenant_id, self$.scope)
      self$.id <- rlang::hash(self$.cache_key)

      self$.oauth_host <- default_azure_host()
      self$.token_url <- default_azure_url(
        endpoint = "token",
        oauth_host = self$.oauth_host,
        tenant_id = self$.tenant_id
      )

      self$.oauth_endpoint <- oauth_endpoint %||% self$.oauth_endpoint

      if (!is.null(self$.oauth_endpoint)) {
        self$.oauth_url <- default_azure_url(
          endpoint = self$.oauth_endpoint,
          oauth_host = self$.oauth_host,
          tenant_id = self$.tenant_id
        )
      }

      self$.oauth_client <- httr2::oauth_client(
        name = self$.id,
        id = self$.client_id,
        secret = self$.client_secret,
        token_url = self$.token_url,
        auth = "body"
      )

      self$validate()
    },
    validate = function() {
      validate_scope(self$.scope)
      validate_tenant_id(self$.tenant_id)
      invisible(self)
    },
    is_interactive = function() {
      FALSE
    },
    print = function() {
      cli::cli_text(cli::style_bold("<", paste(class(self), collapse = "/"), ">"))

      nms <- r6_get_public_fields(cls = r6_get_class(self))
      pfields <- rlang::env_get_list(env = self, nms = nms)
      names(pfields) <- sub("^\\.", "", names(pfields))

      # Filter out NULL/empty values and redact sensitive fields
      pfields <- Filter(length, pfields)
      redacted <- list_redact(pfields, c("client_secret", "key"))

      bullets(redacted)
      invisible(self)
    }
  )
)


collapse_scope <- function(scope) {
  paste(scope, collapse = " ")
}
