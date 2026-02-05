#' Launch the Shiny app for incidence results
#'
#' Starts the package's Shiny app to visualize incidence results. The app
#' reads result files from the given output folder.
#'
#' @param outputFolder Path to the folder where study results were saved
#'   (e.g. by \code{\link{runStudy}}). The app looks here for exported
#'   incidence results.
#' @return Invoked for side effect (launches the Shiny app).
#' @export
launchShinyApp <- function(outputFolder) {
  outputFolder <- normalizePath(outputFolder, mustWork = TRUE)
  options(exampleStudy.outputFolder = outputFolder)
  appDir <- system.file("shiny", "app.R", package = "ExampleStudy")
  if (appDir == "") {
    stop("Shiny app not found. Reinstall the package.")
  }
  shiny::runApp(appDir, launch.browser = TRUE)
}
