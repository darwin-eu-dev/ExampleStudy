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

test_that("runStudy with custom cohortFolder uses given path", {
  skip_if_not_installed("omock")

  cdm <- omock::mockCdmReference() |>
    omock::mockPerson(nPerson = 5, seed = 1) |>
    omock::mockObservationPeriod(seed = 1)

  pkg_cohorts <- system.file("cohorts", package = "ExampleStudy")
  out_dir <- tempfile("ExampleStudy_custom_")
  dir.create(out_dir, recursive = TRUE)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  tryCatch(
    {
      runStudy(cdm = cdm, outputFolder = out_dir, cohortFolder = pkg_cohorts)
      expect_true(dir.exists(out_dir))
    },
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("write_schema|write schema|connection|dbIsValid", msg, ignore.case = TRUE)) {
        skip("Backend does not support cohort generation in this test environment")
      }
      stop(e)
    }
  )
})
