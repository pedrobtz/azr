test_that("wi_resp_body_json wraps invalid JSON responses", {
  resp <- httr2::response(
    status_code = 502,
    url = "https://login.example/token",
    headers = list("content-type" = "text/html"),
    body = charToRaw("<html>bad gateway</html>")
  )

  expect_error(
    wi_resp_body_json(resp),
    class = "azr_workload_identity_invalid_json_response"
  )
})

test_that("wi_resp_body_json parses valid token JSON responses", {
  resp <- httr2::response(
    headers = list("content-type" = "application/json"),
    body = charToRaw('{"access_token":"abc","expires_in":3600}')
  )

  body <- wi_resp_body_json(resp)

  expect_equal(body$access_token, "abc")
  expect_equal(body$expires_in, 3600)
})
