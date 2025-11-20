test_that("is_hosted_session detects Google Colab", {
  withr::local_envvar(COLAB_RELEASE_TAG = "colab-version-123")
  expect_true(is_hosted_session())
})

test_that("is_hosted_session detects RStudio Server (non-localhost)", {
  withr::local_envvar(
    RSTUDIO_PROGRAM_MODE = "server",
    RSTUDIO_HTTP_REFERER = "https://rstudio.example.com"
  )
  expect_true(is_hosted_session())
})

test_that("is_hosted_session returns FALSE for RStudio Server on localhost", {
  withr::local_envvar(
    RSTUDIO_PROGRAM_MODE = "server",
    RSTUDIO_HTTP_REFERER = "http://localhost:8787",
    COLAB_RELEASE_TAG = ""
  )
  expect_false(is_hosted_session())
})

test_that("is_hosted_session returns FALSE for desktop RStudio", {
  withr::local_envvar(
    RSTUDIO_PROGRAM_MODE = "desktop",
    COLAB_RELEASE_TAG = ""
  )
  expect_false(is_hosted_session())
})

test_that("is_hosted_session returns FALSE when no hosted environment detected", {
  withr::local_envvar(
    COLAB_RELEASE_TAG = "",
    RSTUDIO_PROGRAM_MODE = NA,
    RSTUDIO_HTTP_REFERER = NA
  )
  expect_false(is_hosted_session())
})

test_that("redacted creates redacted object", {
  r <- redacted()
  expect_s3_class(r, "redacted")
  expect_type(r, "list")
  expect_length(r, 0)
})

test_that("format.redacted returns grey REDACTED text", {
  r <- redacted()
  formatted <- format(r)
  expect_type(formatted, "character")
  expect_match(formatted, "REDACTED")
})

test_that("print.redacted prints REDACTED", {
  r <- redacted()
  output <- capture.output(print(r))
  expect_match(output, "REDACTED")
})

test_that("list_redact redacts specified names (case sensitive)", {
  x <- list(password = "secret123", username = "user", data = "public")
  result <- list_redact(x, c("password", "username"))

  expect_s3_class(result$password, "redacted")
  expect_s3_class(result$username, "redacted")
  expect_equal(result$data, "public")
})

test_that("list_redact is case sensitive by default", {
  x <- list(Password = "secret", password = "secret2", data = "public")
  result <- list_redact(x, "password")

  expect_equal(result$Password, "secret")
  expect_s3_class(result$password, "redacted")
  expect_equal(result$data, "public")
})

test_that("list_redact can be case insensitive", {
  x <- list(Password = "secret", USERNAME = "user", data = "public")
  result <- list_redact(x, c("password", "username"), case_sensitive = FALSE)

  expect_s3_class(result$Password, "redacted")
  expect_s3_class(result$USERNAME, "redacted")
  expect_equal(result$data, "public")
})

test_that("list_redact handles non-existent names", {
  x <- list(password = "secret", data = "public")
  result <- list_redact(x, c("password", "nonexistent"))

  expect_s3_class(result$password, "redacted")
  expect_equal(result$data, "public")
  expect_null(result$nonexistent)
})

test_that("list_redact does not redact empty vectors", {
  x <- list(password = character(0), data = "public")
  result <- list_redact(x, "password")

  expect_equal(result$password, list(), ignore_attr = TRUE)
  expect_equal(result$data, "public")
})
