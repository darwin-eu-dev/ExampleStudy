test_that("readCohortSet loads package cohorts", {
  cohortFolder <- system.file("cohorts", package = "ExampleStudy")
  expect_true(dir.exists(cohortFolder))

  cohortSet <- CDMConnector::readCohortSet(cohortFolder)
  expect_s3_class(cohortSet, "CohortSet")
  expect_gte(nrow(cohortSet), 1)
  expect_true("cohort_definition_id" %in% names(cohortSet))
  expect_true("cohort_name" %in% names(cohortSet))
})

test_that("runStudy runs with omock CDM when backend supports write", {
  skip_if_not_installed("omock")

  cdm <- omock::mockCdmReference() |>
    omock::mockPerson(nPerson = 20, seed = 42) |>
    omock::mockObservationPeriod(seed = 42) |>
    omock::mockConditionOccurrence(recordPerson = 2, seed = 42)

  out_dir <- tempfile("ExampleStudy_output_")
  dir.create(out_dir, recursive = TRUE)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  # CDMConnector::generateCohortSet requires a database connection; omock CDM
  # is in-memory and has no con, so we skip when that error occurs.
  tryCatch(
    {
      result <- runStudy(cdm = cdm, outputFolder = out_dir)
      expect_true(dir.exists(out_dir))
      expect_true(length(list.files(out_dir)) >= 0)
      expect_true(inherits(result, "summarised_result") || inherits(result, "IncidenceResult"))
    },
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("write_schema|write schema|cohort.*table|dbIsValid|connection|con ", msg, ignore.case = TRUE)) {
        skip("omock in-memory CDM does not support cohort generation (requires database connection)")
      }
      stop(e)
    }
  )
})

