test_that("omock builds a valid empty CDM reference", {
  skip_if_not_installed("omock")

  cdm <- omock::mockCdmReference()
  expect_s3_class(cdm, "cdm_reference")
})

test_that("omock builds CDM with person and observation_period", {
  skip_if_not_installed("omock")

  cdm <- omock::mockCdmReference() |>
    omock::mockPerson(nPerson = 5, seed = 1) |>
    omock::mockObservationPeriod(seed = 1)

  expect_true("person" %in% names(cdm))
  expect_true("observation_period" %in% names(cdm))

  expect_gte(nrow(dplyr::collect(cdm$person)), 5)
  expect_gte(nrow(dplyr::collect(cdm$observation_period)), 5)

  person <- dplyr::collect(cdm$person)
  expect_true("person_id" %in% names(person))
  expect_true("gender_concept_id" %in% names(person))
  expect_true("year_of_birth" %in% names(person))

  obs_period <- dplyr::collect(cdm$observation_period)
  expect_true("person_id" %in% names(obs_period))
  expect_true("observation_period_start_date" %in% names(obs_period))
  expect_true("observation_period_end_date" %in% names(obs_period))
})

test_that("omock builds CDM with condition_occurrence", {
  skip_if_not_installed("omock")

  cdm <- omock::mockCdmReference() |>
    omock::mockPerson(nPerson = 10, seed = 1) |>
    omock::mockObservationPeriod(seed = 1) |>
    omock::mockConditionOccurrence(recordPerson = 1, seed = 1)

  expect_true("condition_occurrence" %in% names(cdm))
  cond <- dplyr::collect(cdm$condition_occurrence)
  expect_true("person_id" %in% names(cond))
  expect_true("condition_concept_id" %in% names(cond))
  expect_true("condition_start_date" %in% names(cond))
  expect_gte(nrow(cond), 1)
})

test_that("omock mockCdmFromTables builds CDM from cohort-like tables", {
  skip_if_not_installed("omock")
  skip_if_not_installed("dplyr")

  cohort <- dplyr::tibble(
    cohort_definition_id = c(1L, 1L, 2L),
    subject_id = c(1L, 2L, 1L),
    cohort_start_date = as.Date(c("2020-01-01", "2020-02-01", "2021-01-01")),
    cohort_end_date = as.Date(c("2020-12-31", "2020-12-31", "2021-12-31"))
  )

  cdm <- omock::mockCdmFromTables(tables = list(my_cohort = cohort), seed = 1)

  expect_true("person" %in% names(cdm))
  expect_true("observation_period" %in% names(cdm))
  expect_true("my_cohort" %in% names(cdm))

  my_cohort <- dplyr::collect(cdm$my_cohort)
  expect_equal(nrow(my_cohort), 3)
  expect_equal(unique(my_cohort$cohort_definition_id), c(1L, 2L))
})
