#' Run the example incidence study
#'
#' Runs incidence estimation for the condition cohort(s) defined in the
#' package's cohort set. Requires a CDM connection and writes results to
#' \code{outputFolder}.
#'
#' @param cdm A CDM reference object (from CDMConnector).
#' @param outputFolder Path to the folder where results will be saved.
#' @param minCellCount Minimum cell count for suppression of results. Defaults to 5.
#' @return The incidence result object (invisibly).
#' @export
runStudy <- function(cdm, outputFolder, minCellCount = 5) {

  log_file <- file.path(outputFolder, "log.txt")
  if (!dir.exists(outputFolder)) {
    dir.create(outputFolder, recursive = TRUE)
  }
  log_appenders <- list(
    log4r::console_appender(),
    log4r::file_appender(log_file)
  )
  logger <- log4r::logger("INFO", appenders = log_appenders)

  log4r::info(logger, "ExampleStudy: starting incidence study.")
  log4r::info(logger, paste("Study package version", packageVersion("ExampleStudy")))
  log4r::info(logger, paste0("Output folder: ", outputFolder))


  log4r::info(logger, "Getting CDM snapshot")
  snap <- CDMConnector::snapshot(cdm)
  readr::write_csv(snap, file.path(outputFolder, "snapshot.csv"))

  cohortFolder <- system.file("cohorts", package = "ExampleStudy", mustWork = TRUE)
  cohortSet <- CDMConnector::readCohortSet(cohortFolder)

  log4r::info(logger, "Generating outcome cohort set (diabetes_cohort).")
  cdm <- CDMConnector::generateCohortSet(
    cdm = cdm,
    cohortSet = cohortSet,
    name = "diabetes_cohort",
    overwrite = TRUE
  )

  cohortCounts <- CDMConnector::cohortCount(cdm$diabetes_cohort) %>%
    dplyr::left_join(CDMConnector::settings(cdm$diabetes_cohort), by = "cohort_definition_id")

  readr::write_csv(cohortCounts, file.path(outputFolder, "cohortCounts.csv"))

  log4r::info(logger, "Generating denominator cohort set.")
  cdm <- IncidencePrevalence::generateDenominatorCohortSet(
    cdm = cdm,
    name = "denominator",
    cohortDateRange = as.Date(c("2010-01-01", "2020-12-31")),
    ageGroup = list(c(18, 150)),
    daysPriorObservation = 0
  )

  log4r::info(logger, "Estimating incidence (overall and by year).")
  incidence <- IncidencePrevalence::estimateIncidence(
    cdm = cdm,
    denominatorTable = "denominator",
    outcomeTable = "diabetes_cohort",
    interval = c("overall", "years")
  )

  log4r::info(logger, paste0("Exporting results to ", outputFolder, " (minCellCount = ", minCellCount, ")."))
  omopgenerics::exportSummarisedResult(
    incidence,
    path = outputFolder,
    minCellCount = minCellCount,
    fileName = "incidence"
  )
  log4r::info(logger, "Results exported successfully.")
  log4r::info(logger, "ExampleStudy: incidence study finished.")

  invisible(incidence)
}
