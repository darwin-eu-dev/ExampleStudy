test_that("Shiny app is found in package", {
  app_path <- system.file("shiny", "app.R", package = "ExampleStudy")
  expect_true(nzchar(app_path), info = "Shiny app app.R should be in inst/shiny/")
})

test_that("Shiny app loads and returns a shiny.appobj", {
  app_path <- system.file("shiny", "app.R", package = "ExampleStudy")
  skip_if(!nzchar(app_path), "Shiny app not found (package not installed?)")

  # Set option so app.R can resolve outputFolder (required by app)
  old <- options(exampleStudy.outputFolder = tempdir())
  on.exit(options(old))
  env <- new.env()
  source(app_path, local = env)
  app <- shiny::shinyApp(env$ui, env$server)
  expect_s3_class(app, "shiny.appobj")
})

test_that("Shiny app launches without error", {
  app_dir <- system.file("shiny", "app.R", package = "ExampleStudy")
  skip_if(!nzchar(app_dir), "Shiny app not found (package not installed?)")
  skip_if_not_installed("callr")

  # Launch app in a subprocess (pass app path so child does not need package installed)
  err <- tryCatch(
    callr::r(
      function(app_path, out_dir) {
        options(exampleStudy.outputFolder = out_dir)
        shiny::runApp(app_path, launch.browser = FALSE)
      },
      args = list(app_path = app_dir, out_dir = tempdir()),
      timeout = 3
    ),
    error = identity
  )
  # Timeout means the app was running; any other error means app failed to start
  expect_true(inherits(err, "callr_timeout_error"), info = paste("App failed:", conditionMessage(err)))
})
