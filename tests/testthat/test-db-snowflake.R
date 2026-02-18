# Snowflake DB tests. Skip when SNOWFLAKE_USER is unset or when ODBC driver cannot be loaded (e.g. in CI with wrong driver path).
test_that("Snowflake connection works when driver is available", {
  con <- get_snowflake_connection_or_skip()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  expect_true(DBI::dbIsValid(con))
})
