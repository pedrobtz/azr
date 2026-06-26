Credential <- R6::R6Class(
  classname = "Credential",
  public = list(
    .id = NULL,
    .name = NULL,
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
    .classname = NULL,
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      client_secret = NULL,
      use_cache = c("disk", "memory"),
      offline = FALSE,
      oauth_endpoint = NULL,
      name = NULL
    ) {
      self$.classname <- paste(class(self), collapse = "/")

      self$.scope <- scope %||% default_azure_scope(resource = "azure_arm")

      if (isTRUE(offline)) {
        self$.scope <- unique(c(self$.scope, "offline_access"))
      }

      self$.scope_str <- collapse_scope(self$.scope)
      self$.resource <- get_scope_resource(self$.scope)

      self$.client_id <- client_id %||% default_azure_client_id()
      self$.client_secret <- client_secret %||% default_azure_client_secret()

      self$.tenant_id <- tenant_id %||% default_azure_tenant_id()
      self$.use_cache <- credential_default_use_cache(use_cache)

      self$.cache_key <- list(
        client_id = self$.client_id,
        tenant_id = self$.tenant_id,
        scope = self$.scope,
        classname = self$.classname
      )
      self$.id <- rlang::hash(self$.cache_key)

      self$.name <- name %||% self$.id

      self$.oauth_host <- default_azure_host_unchecked()
      self$.token_url <- default_azure_url_unchecked(
        endpoint = "token",
        oauth_host = self$.oauth_host,
        tenant_id = self$.tenant_id
      )

      self$.oauth_endpoint <- oauth_endpoint %||% self$.oauth_endpoint

      if (!is.null(self$.oauth_endpoint)) {
        self$.oauth_url <- default_azure_url_unchecked(
          endpoint = self$.oauth_endpoint,
          oauth_host = self$.oauth_host,
          tenant_id = self$.tenant_id
        )
      }

      self$.oauth_client <- httr2::oauth_client(
        name = credential_safe_string(self$.name),
        id = credential_safe_string(self$.client_id),
        secret = credential_safe_secret(self$.client_secret),
        token_url = self$.token_url,
        auth = "body"
      )

      self$validate()

      # Lock all public fields to prevent modification
      lockBinding(".id", self)
      lockBinding(".name", self)
      lockBinding(".scope", self)
      lockBinding(".scope_str", self)
      lockBinding(".resource", self)
      lockBinding(".client_id", self)
      lockBinding(".client_secret", self)
      lockBinding(".tenant_id", self)
      lockBinding(".use_cache", self)
      lockBinding(".cache_key", self)
      lockBinding(".oauth_client", self)
      lockBinding(".oauth_host", self)
      lockBinding(".oauth_endpoint", self)
      lockBinding(".oauth_url", self)
      lockBinding(".token_url", self)
      lockBinding(".classname", self)
    },
    validate = function() {
      private$validate_base()
      invisible(self)
    },
    is_interactive = function() {
      FALSE
    },
    print = function() {
      cli::cli_text(cli::style_bold(
        "<",
        paste(class(self), collapse = "/"),
        ">"
      ))

      nms <- r6_get_public_fields(
        cls = r6_get_class(
          self,
          envir = getNamespace(methods::getPackageName())
        )
      )

      pfields <- rlang::env_get_list(env = self, nms = nms)
      names(pfields) <- sub("^\\.", "", names(pfields))

      # Filter out NULL/empty values and redact sensitive fields
      pfields <- Filter(length, pfields)
      redacted <- list_redact(pfields, c("client_secret", "key"))

      bullets(redacted)
      invisible(self)
    }
  ),
  private = list(
    validate_base = function() {
      validate_scope(self$.scope)
      validate_tenant_id(self$.tenant_id)
      validate_required_string(self$.client_id, "client_id")
      validate_use_cache(self$.use_cache)

      if (!is.null(self$.oauth_endpoint)) {
        if (
          !is.character(self$.oauth_endpoint) ||
            length(self$.oauth_endpoint) != 1L ||
            is.na(self$.oauth_endpoint) ||
            !self$.oauth_endpoint %in% c("authorize", "token", "devicecode")
        ) {
          cli::cli_abort(
            "Argument {.arg oauth_endpoint} must be one of {.val authorize}, {.val token}, or {.val devicecode}."
          )
        }
      }

      invisible(self)
    }
  )
)


is_credential <- function(x) {
  R6::is.R6(x) &&
    inherits(x, c("Credential", "DefaultCredential", "CachedTokenCredential"))
}


collapse_scope <- function(scope) {
  paste(scope, collapse = " ")
}


credential_default_use_cache <- function(use_cache) {
  if (identical(use_cache, c("disk", "memory"))) {
    return("disk")
  }

  use_cache
}


credential_safe_string <- function(x, default = "") {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    return(default)
  }

  x
}


credential_safe_secret <- function(x) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    return(NULL)
  }

  x
}
