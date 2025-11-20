test_that("validate_tenant_id accepts valid tenant IDs", {
  expect_true(validate_tenant_id("common"))
  expect_true(validate_tenant_id("my-tenant-id"))
  expect_true(validate_tenant_id("tenant.with.dots"))
  expect_true(validate_tenant_id("12345-67890"))
  expect_true(validate_tenant_id("abc123DEF456"))
})

test_that("validate_tenant_id rejects non-string inputs", {
  expect_error(validate_tenant_id(123), "must be a single string")
  expect_error(validate_tenant_id(c("a", "b")), "must be a single string")
  expect_error(validate_tenant_id(NULL), "must be a single string")
})

test_that("validate_tenant_id rejects invalid tenant IDs", {
  expect_error(validate_tenant_id("tenant_with_underscore"), "not valid")
  expect_error(validate_tenant_id("tenant with spaces"), "not valid")
  expect_error(validate_tenant_id("tenant/slash"), "not valid")
  expect_error(validate_tenant_id("tenant@special"), "not valid")
})

test_that("validate_scope accepts valid scopes", {
  expect_true(validate_scope("https://management.azure.com/.default"))
  expect_true(validate_scope("openid"))
  expect_true(validate_scope("user.read"))
  expect_true(validate_scope(c("openid", "profile", "email")))
  expect_true(validate_scope("https://graph.microsoft.com/.default"))
})

test_that("validate_scope rejects non-character inputs", {
  expect_error(validate_scope(123), "must be a character vector")
  expect_error(validate_scope(NULL), "must be a character vector")
  expect_error(validate_scope(list("a")), "must be a character vector")
})

test_that("validate_scope rejects invalid scopes", {
  expect_error(validate_scope("scope with spaces"), "not valid")
  expect_error(validate_scope("scope@invalid"), "not valid")
  expect_error(validate_scope(c("valid.scope", "invalid scope")), "not valid")
})

test_that("get_scope_resource extracts resource from HTTP scope", {
  result <- get_scope_resource("https://management.azure.com/.default")
  expect_equal(result, "https://management.azure.com")

  result <- get_scope_resource("https://graph.microsoft.com/.default")
  expect_equal(result, "https://graph.microsoft.com")

  result <- get_scope_resource("https://vault.azure.net/.default")
  expect_equal(result, "https://vault.azure.net")
})

test_that("get_scope_resource handles trailing slash", {
  result <- get_scope_resource("https://management.azure.com/")
  expect_equal(result, "https://management.azure.com")
})

test_that("get_scope_resource returns NULL for non-HTTP scopes", {
  expect_null(get_scope_resource("openid"))
  expect_null(get_scope_resource("user.read"))
})

test_that("get_scope_resource returns NULL for multiple HTTP scopes", {
  scopes <- c(
    "https://management.azure.com/.default",
    "https://graph.microsoft.com/.default"
  )
  expect_null(get_scope_resource(scopes))
})

test_that("get_scope_resource returns NULL for no HTTP scopes", {
  scopes <- c("openid", "profile", "email")
  expect_null(get_scope_resource(scopes))
})

test_that("is_empty detects NULL", {
  expect_true(is_empty(NULL))
})

test_that("is_empty detects NA values", {
  expect_true(is_empty(NA))
  expect_true(is_empty(NA_character_))
  expect_true(is_empty(NA_integer_))
})

test_that("is_empty detects empty strings", {
  expect_true(is_empty(""))
})

test_that("is_empty returns FALSE for non-empty values", {
  expect_false(is_empty("test"))
  expect_false(is_empty(123))
  expect_false(is_empty(TRUE))
})

test_that("is_empty returns FALSE for vectors with multiple elements", {
  expect_false(is_empty(c("a", "b")))
  expect_false(is_empty(1:10))
})

test_that("is_empty_vec works on lists", {
  x <- list(a = "value", b = "", c = NA, d = NULL, e = "test")
  result <- is_empty_vec(x)

  expect_equal(length(result), 5)
  expect_false(result[1]) # "value"
  expect_true(result[2]) # ""
  expect_true(result[3]) # NA
  expect_true(result[4]) # NULL
  expect_false(result[5]) # "test"
})

test_that("is_empty_vec returns logical vector", {
  x <- list(a = 1, b = NULL, c = "test")
  result <- is_empty_vec(x)

  expect_type(result, "logical")
  expect_length(result, 3)
})

test_that("get_env_config returns formatted bullet list", {
  withr::local_envvar(
    AZURE_TENANT_ID = NA,
    AZURE_CLIENT_ID = NA,
    AZURE_CLIENT_SECRET = NA,
    AZURE_AUTHORITY_HOST = NA
  )

  result <- get_env_config()

  expect_type(result, "character")
  expect_length(result, 5)
  expect_named(result, c("*", "*", "*", "*", "*"))
})

test_that("get_env_config shows environment variables when set", {
  withr::local_envvar(
    AZURE_TENANT_ID = "my-tenant",
    AZURE_CLIENT_ID = "my-client",
    AZURE_CLIENT_SECRET = "my-secret",
    AZURE_AUTHORITY_HOST = "login.microsoftonline.us"
  )

  result <- get_env_config()

  expect_match(result[1], "my-tenant")
  expect_match(result[2], "my-client")
  expect_match(result[3], "REDACTED")
  expect_match(result[4], "login.microsoftonline.us")
})

test_that("get_env_config shows defaults when not set", {
  withr::local_envvar(
    AZURE_TENANT_ID = "",
    AZURE_CLIENT_ID = "",
    AZURE_CLIENT_SECRET = "",
    AZURE_AUTHORITY_HOST = ""
  )

  result <- get_env_config()

  expect_match(result[1], "default")
  expect_match(result[2], "default")
  expect_match(result[3], "not set")
  expect_match(result[4], "default")
})

# Tests for r6_get_initialize_arguments

test_that("r6_get_initialize_arguments returns NULL for NULL input", {
  result <- r6_get_initialize_arguments(NULL)
  expect_null(result)
})

test_that("r6_get_initialize_arguments errors on non-R6 class", {
  expect_error(
    r6_get_initialize_arguments("not-a-class"),
    "must be an R6 class"
  )

  expect_error(
    r6_get_initialize_arguments(123),
    "must be an R6 class"
  )

  expect_error(
    r6_get_initialize_arguments(list()),
    "must be an R6 class"
  )
})

test_that("r6_get_initialize_arguments works with R6 class with no initialize", {
  TestClassNoInit <- R6::R6Class(
    classname = "TestClassNoInit",
    public = list(
      value = NULL
    )
  )

  result <- r6_get_initialize_arguments(TestClassNoInit)
  expect_null(result)
})

test_that("r6_get_initialize_arguments works with R6 class with initialize", {
  TestClassWithInit <- R6::R6Class(
    classname = "TestClassWithInit",
    public = list(
      initialize = function(x) {
        self$x <- x
      },
      x = NULL
    )
  )

  result <- r6_get_initialize_arguments(TestClassWithInit)
  expect_equal(result, c("x"))
})

test_that("r6_get_initialize_arguments handles multiple parameters", {
  TestClassMultiParam <- R6::R6Class(
    classname = "TestClassMultiParam",
    public = list(
      initialize = function(x, y, z = NULL) {
        self$x <- x
        self$y <- y
        self$z <- z
      },
      x = NULL,
      y = NULL,
      z = NULL
    )
  )

  result <- r6_get_initialize_arguments(TestClassMultiParam)
  expect_equal(result, c("x", "y", "z"))
})

test_that("r6_get_initialize_arguments handles class inheritance", {
  ParentClass <- R6::R6Class(
    classname = "ParentClass",
    public = list(
      initialize = function(parent_arg) {
        self$parent_arg <- parent_arg
      },
      parent_arg = NULL
    )
  )

  ChildClass <- R6::R6Class(
    classname = "ChildClass",
    inherit = ParentClass,
    public = list(
      initialize = function(parent_arg, child_arg) {
        super$initialize(parent_arg)
        self$child_arg <- child_arg
      },
      child_arg = NULL
    )
  )

  result <- r6_get_initialize_arguments(ChildClass)
  expect_equal(result, c("parent_arg", "child_arg"))
})

test_that("r6_get_initialize_arguments inherits from parent when no initialize", {
  ParentClass <- R6::R6Class(
    classname = "ParentClass",
    public = list(
      initialize = function(x, y) {
        self$x <- x
        self$y <- y
      },
      x = NULL,
      y = NULL
    )
  )

  ChildClassNoInit <- R6::R6Class(
    classname = "ChildClassNoInit",
    inherit = ParentClass,
    public = list(
      z = NULL
    )
  )

  result <- r6_get_initialize_arguments(ChildClassNoInit)
  expect_equal(result, c("x", "y"))
})

# Tests for r6_get_public_fields

test_that("r6_get_public_fields errors on non-R6 class", {
  expect_error(
    r6_get_public_fields("not-a-class"),
    "must be an R6 class"
  )

  expect_error(
    r6_get_public_fields(123),
    "must be an R6 class"
  )

  expect_error(
    r6_get_public_fields(list()),
    "must be an R6 class"
  )
})

test_that("r6_get_public_fields returns fields from simple R6 class", {
  SimpleClass <- R6::R6Class(
    classname = "SimpleClass",
    public = list(
      field1 = NULL,
      field2 = NULL,
      method1 = function() {
        "method"
      }
    )
  )

  result <- r6_get_public_fields(SimpleClass)
  expect_equal(result, c("field1", "field2"))
})

test_that("r6_get_public_fields handles class with no fields", {
  NoFieldsClass <- R6::R6Class(
    classname = "NoFieldsClass",
    public = list(
      method1 = function() {
        "method"
      }
    )
  )

  result <- r6_get_public_fields(NoFieldsClass)
  expect_equal(result, NULL)
})

test_that("r6_get_public_fields includes parent fields", {
  ParentClass <- R6::R6Class(
    classname = "ParentClass",
    public = list(
      parent_field1 = NULL,
      parent_field2 = NULL
    )
  )

  ChildClass <- R6::R6Class(
    classname = "ChildClass",
    inherit = ParentClass,
    public = list(
      child_field1 = NULL,
      child_field2 = NULL
    )
  )

  result <- r6_get_public_fields(ChildClass)
  expect_equal(
    result,
    c("child_field1", "child_field2", "parent_field1", "parent_field2")
  )
})

test_that("r6_get_public_fields handles multiple levels of inheritance", {
  GrandparentClass <- R6::R6Class(
    classname = "GrandparentClass",
    public = list(
      grandparent_field = NULL
    )
  )

  ParentClass <- R6::R6Class(
    classname = "ParentClass",
    inherit = GrandparentClass,
    public = list(
      parent_field = NULL
    )
  )

  ChildClass <- R6::R6Class(
    classname = "ChildClass",
    inherit = ParentClass,
    public = list(
      child_field = NULL
    )
  )

  result <- r6_get_public_fields(ChildClass)
  expect_equal(
    result,
    c("child_field", "parent_field", "grandparent_field")
  )
})

test_that("r6_get_public_fields works with class that has only inherited fields", {
  ParentClass <- R6::R6Class(
    classname = "ParentClass",
    public = list(
      parent_field = NULL
    )
  )

  ChildClass <- R6::R6Class(
    classname = "ChildClass",
    inherit = ParentClass,
    public = list(
      method1 = function() {
        "method"
      }
    )
  )

  result <- r6_get_public_fields(ChildClass)
  expect_equal(result, c("parent_field"))
})

# Tests for r6_get_class

test_that("r6_get_class errors on non-R6 object", {
  expect_error(
    r6_get_class("not-an-object"),
    "must be an R6 object"
  )

  expect_error(
    r6_get_class(123),
    "must be an R6 object"
  )

  expect_error(
    r6_get_class(list()),
    "must be an R6 object"
  )
})

test_that("r6_get_class returns the class definition from an instance", {
  TestClass <- R6::R6Class(
    classname = "TestClass",
    public = list(
      field1 = NULL,
      initialize = function(x) {
        self$field1 <- x
      }
    )
  )

  instance <- TestClass$new(x = "test")
  result <- r6_get_class(instance)

  expect_true(R6::is.R6Class(result))
  expect_equal(result$classname, "TestClass")
})

test_that("r6_get_class works with inherited classes", {
  ParentClass <- R6::R6Class(
    classname = "ParentClass",
    public = list(
      parent_field = NULL
    )
  )

  ChildClass <- R6::R6Class(
    classname = "ChildClass",
    inherit = ParentClass,
    public = list(
      child_field = NULL
    )
  )

  instance <- ChildClass$new()
  result <- r6_get_class(instance)

  expect_true(R6::is.R6Class(result))
  expect_equal(result$classname, "ChildClass")
})

test_that("r6_get_class can access class methods from instance", {
  TestClass <- R6::R6Class(
    classname = "TestClass",
    public = list(
      value = 10,
      get_value = function() {
        self$value
      }
    )
  )

  instance <- TestClass$new()
  cls <- r6_get_class(instance)

  expect_setequal(names(cls$public_methods), c("get_value", "clone"))
  expect_equal(names(cls$public_fields), "value")
})
