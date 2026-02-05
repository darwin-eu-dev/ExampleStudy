# ExampleStudy

Example OHDSI study package for **testing [Arachne](https://github.com/OHDSI/Arachne)**. It demonstrates incidence estimation on an OMOP CDM using standard OHDSI tooling.

## What it does

- **Cohort**: Type 2 diabetes (LEGEND-style definition in `inst/cohorts/`).
- **Analysis**: Incidence estimation via `IncidencePrevalence` (denominator 2010–2020, age 18+, 365 days prior observation).
- **Output**: Summarised results exported to a folder; optional Shiny app to explore them.

## How to run the study

1. **Get the code**  
   Clone the repo or download and extract the source:
   ```bash
   git clone <repository-url>
   cd ExampleStudy
   ```
   Or download the package as a ZIP and extract it.

2. **Install the package** (from the `ExampleStudy` directory):
   ```r
   devtools::install()
   ```

3. **Execute the study script**  
   From the package root in R:
   ```r
   source("extras/codeToRun.R")
   ```
   That script sets an output folder, optionally runs the study (if you configure a CDM connection), and launches the Shiny app. Edit `extras/codeToRun.R` to point to your CDM and uncomment the `runStudy(cdm, outputFolder)` call if you want to run the incidence analysis.

## Quick start (after installation)

```r
# Run the study (requires a CDM connection)
ExampleStudy::runStudy(cdm, outputFolder = "path/to/output")

# Launch the Shiny app
ExampleStudy::launchShinyApp(outputFolder)
```

Requires: `CDMConnector`, `IncidencePrevalence`, `omopgenerics`, and (for the app) `shiny`, `plotly`, `ggplot2`, `dplyr`.

## Arachne

Use this package as a minimal, self-contained study when validating or testing Arachne workflows (study execution, result export, Shiny integration, etc.).
