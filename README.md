# ExampleStudy

Example OHDSI study package for **testing [Arachne](https://github.com/OHDSI/Arachne)**. 

## What it does

- **Cohort**: Type 2 diabetes (LEGEND-style definition in `inst/cohorts/`).
- **Analysis**: Incidence estimation via `IncidencePrevalence`
- **Output**: Summarised results exported to a folder; optional Shiny app to explore them.

## How to run the study

1. **Get the code**  
   Clone the repo or download and extract the source:
   ```bash
   git clone git@github.com:darwin-eu-dev/ExampleStudy.git
   cd ExampleStudy
   ```
   Or download the package as a ZIP and extract it.

2. **Install the package** (from the `ExampleStudy` directory):
   ```r
   devtools::install()
   ```

3. **Execute the study script**  
   Open `extras/codeToRun.R`, modify the connection information, output folder, and minCellCount.
   Then run the script.


## Arachne

Use this package as a minimal, self-contained study when validating or testing
Arachne workflows (study execution, result export, Shiny integration, etc.).
