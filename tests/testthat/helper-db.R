# Helper to create DB connections for tests. Uses env vars (see README or Dockerfile.base).
# For Snowflake: set SNOWFLAKE_DRIVER to the driver name (e.g. "SnowflakeDSIIDriver" in container).
get_connection <- function(dbms) {

  if (dbms == "postgres") {
    dbname <- Sys.getenv("CDM5_POSTGRESQL_DBNAME")
    host <- Sys.getenv("CDM5_POSTGRESQL_HOST")
    user <- Sys.getenv("CDM5_POSTGRESQL_USER")
    password <- Sys.getenv("CDM5_POSTGRESQL_PASSWORD")
    port <- as.integer(Sys.getenv("CDM5_POSTGRESQL_PORT", "5432"))
    return(DBI::dbConnect(RPostgres::Postgres(),
                          dbname = dbname,
                          host = host,
                          port = port,
                          user = user,
                          password = password))
  }

  if (dbms == "snowflake" && Sys.getenv("SNOWFLAKE_USER") != "") {
    tryCatch(
      return(DBI::dbConnect(odbc::odbc(),
                            SERVER = Sys.getenv("SNOWFLAKE_SERVER"),
                            UID = Sys.getenv("SNOWFLAKE_USER"),
                            PWD = Sys.getenv("SNOWFLAKE_PASSWORD"),
                            DATABASE = "SCRATCH",
                            WAREHOUSE = Sys.getenv("SNOWFLAKE_WAREHOUSE"),
                            DRIVER = Sys.getenv("SNOWFLAKE_DRIVER"))),
      error = function(e) {
        msg <- conditionMessage(e)
        if (grepl("Can't open lib|file not found", msg, ignore.case = TRUE)) {
          rlang::abort(
            "Snowflake ODBC driver not available (driver library could not be loaded).",
            class = c("snowflake_driver_unavailable", "rlang_error")
          )
        }
        stop(e)
      }
    )
  }

  if (dbms == "spark" && Sys.getenv("DATABRICKS_HTTPPATH") != "") {
    message("connecting to databricks")
    con <- DBI::dbConnect(
      odbc::databricks(),
      httpPath = Sys.getenv("DATABRICKS_HTTPPATH"),
      useNativeQuery = FALSE,
      bigint = "numeric"
    )
    return(con)
  }

  if (dbms == "sqlserver" && Sys.getenv("CDM5_SQL_SERVER_SERVER") != "") {
    message("connecting to sql server")

    con <- DBI::dbConnect(odbc::odbc(),
                          Driver   = Sys.getenv("SQL_SERVER_DRIVER"),
                          Server   = Sys.getenv("CDM5_SQL_SERVER_SERVER"),
                          Database = Sys.getenv("CDM5_SQL_SERVER_CDM_DATABASE"),
                          UID      = Sys.getenv("CDM5_SQL_SERVER_USER"),
                          PWD      = Sys.getenv("CDM5_SQL_SERVER_PASSWORD"),
                          TrustServerCertificate="yes",
                          Port     = Sys.getenv("CDM5_SQL_SERVER_PORT"))

    return(con)
  }


  rlang::abort("Could not create connection. Are some environment variables missing?")
}

# Use in tests that need Snowflake: returns a connection or skips if driver/creds unavailable.
get_snowflake_connection_or_skip <- function() {
  if (Sys.getenv("SNOWFLAKE_USER") == "") {
    testthat::skip("SNOWFLAKE_USER not set")
  }
  tryCatch(
    get_connection("snowflake"),
    error = function(e) {
      if (inherits(e, "snowflake_driver_unavailable")) {
        testthat::skip("Snowflake ODBC driver not available (driver library could not be loaded)")
      }
      stop(e)
    }
  )
}
