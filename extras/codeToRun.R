# Run the ExampleStudy and launch the Shiny app

renv::restore()
library(ExampleStudy)
library(CDMConnector)

# Output folder for results
outputFolder <- here::here("output")
dir.create(outputFolder, recursive = TRUE, showWarnings = FALSE)

minCellCount = 5

# Replace with your CDM connection
con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir("synpuf-1k"))
cdm <- cdmFromCon(
  con,
  cdmSchema = "main",
  writeSchema = "main")

runStudy(cdm, outputFolder)

# Launch the Shiny app (use the folder where results were saved)
launchResultsExplorer(outputFolder)
