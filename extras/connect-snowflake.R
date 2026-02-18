# Connect to Snowflake from inside the Docker base image.
# Set env vars: SNOWFLAKE_SERVER, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_WAREHOUSE
# (SNOWFLAKE_DRIVER is set in the image to "SnowflakeDSIIDriver"; or use the path below.)
#
# Run from container: Rscript extras/connect-snowflake.R
# Or in R: source("extras/connect-snowflake.R")

library(DBI)
library(odbc)

# Driver: use name (resolved via /etc/odbcinst.ini) or explicit path in the base image
SNOWFLAKE_DRIVER <- Sys.getenv("SNOWFLAKE_DRIVER", "SnowflakeDSIIDriver")
# Explicit path inside the Docker base image (use if name lookup fails):
SNOWFLAKE_DRIVER_PATH <- "/usr/lib/snowflake/odbc/lib/libSnowflake.so"

connect_snowflake <- function(driver = NULL) {
  if (is.null(driver)) driver <- SNOWFLAKE_DRIVER
  DBI::dbConnect(
    odbc::odbc(),
    SERVER   = Sys.getenv("SNOWFLAKE_SERVER"),
    UID      = Sys.getenv("SNOWFLAKE_USER"),
    PWD      = Sys.getenv("SNOWFLAKE_PASSWORD"),
    DATABASE = Sys.getenv("SNOWFLAKE_DATABASE", "SCRATCH"),
    WAREHOUSE = Sys.getenv("SNOWFLAKE_WAREHOUSE"),
    DRIVER   = driver
  )
}

# When env is set, connect and run a quick test (e.g. Rscript extras/connect-snowflake.R)
if (Sys.getenv("SNOWFLAKE_USER") != "") {
  con <- tryCatch(
    connect_snowflake(),
    error = function(e) {
      message("Driver name failed, trying explicit path: ", SNOWFLAKE_DRIVER_PATH)
      connect_snowflake(driver = SNOWFLAKE_DRIVER_PATH)
    }
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  print(DBI::dbGetQuery(con, "SELECT CURRENT_TIMESTAMP AS t"))
  message("Connected successfully.")
}
