# Incidence of Type 2 Diabetes

## Overview

This application presents results from an **incidence study of type 2 diabetes** using the OMOP Common Data Model (CDM). The study estimates how often new type 2 diabetes cases occur in the population over time, stratified by age, sex, and other factors.

## Study Design

- **Outcome**: Type 2 diabetes, defined using a LEGEND-style cohort (see `inst/cohorts/` in the package).
- **Analysis**: Incidence estimation with the **IncidencePrevalence** package.
- **Denominator**: Persons with at least 365 days of prior observation; denominator period 2010–2020.
- **Stratification**: Estimates can be broken down by age group (e.g. 18+), sex, calendar year, and data source (CDM).

## What This App Shows

Use the **Incidence** tab to view and filter incidence estimates, download tables (e.g. as Word), and export plots. Other tabs (e.g. **Demographics**, **Attrition**, **Databases**) provide context on the cohorts and data sources.

Use the **sidebar** to switch tabs. Apply filters (CDM, outcome, age group, sex, interval, years) to focus on specific strata. Use the download buttons on each tab to save tables or figures.

## How to Run the Study

Run the analysis (requires a CDM connection), then launch this app to explore results:

```r
ExampleStudy::runStudy(cdm, outputFolder = "path/to/output")
ExampleStudy::launchShinyApp(outputFolder)
```

This app is part of the **ExampleStudy** package.
