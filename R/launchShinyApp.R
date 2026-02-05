#' Launch the Results Explorer Shiny app
#'
#' @param dataFolder       A folder where the exported zip files with the results are stored.
#'                         Zip files containing results from multiple databases can be placed in the same
#'                         folder.
#' @param launch.browser   Should the app be launched in your default browser, or in a Shiny window.
#'                         Note: copying to clipboard will not work in a Shiny window.
#' @details
#' Launches a Shiny app that allows the user to explore the diagnostics
#'
#' @export
launchResultsExplorer <- function(dataFolder, launch.browser = FALSE, useCachedData = FALSE) {
  appDir <- system.file("ResultsExplorer", package = "ExampleStudy", mustWork = TRUE)
  shinySettings <- list(dataFolder = dataFolder)
  .GlobalEnv$shinySettings <- shinySettings
  on.exit(rm(shinySettings, envir = .GlobalEnv))
  shiny::runApp(appDir, launch.browser = launch.browser)
}

