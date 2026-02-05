# -----------------------------------------------------------------------------
# ExampleStudy Shiny App — AML characterization (P4-C1-007)
# -----------------------------------------------------------------------------

library(shiny)
library(shinydashboard)
library(bslib)
library(dplyr)
library(plotly)
library(ggplot2)
library(DT)
library(gt)
library(gtExtras)
library(IncidencePrevalence)
library(shinycssloaders)
library(shinyWidgets)

# -----------------------------------------------------------------------------
# Data loading
# -----------------------------------------------------------------------------




if (exists("shinySettings", where = .GlobalEnv)) {
  if (!file.exists(shinySettings$dataFolder)) stop("Could not find results data!")
  dataFolder <- shinySettings$dataFolder
} else {
  dataFolder <- "data"
}

snapshot <- readr::read_csv(file.path(dataFolder, "snapshot.csv"))
cohortCounts <- readr::read_csv(file.path(dataFolder, "cohortCounts.csv"))
incidence <- omopgenerics::importSummarisedResult(file.path(dataFolder, "incidence.csv"))

# Global picker options
opt <- list("actions-box" = TRUE, size = 10, "selected-text-format" = "count > 3")

# -----------------------------------------------------------------------------
# Incidence module — derived choices
# -----------------------------------------------------------------------------

incidenceOutcomes <- incidence |>
  visOmopResults::splitGroup() |>
  pull(outcome_cohort_name) |>
  unique()

incidenceYearChoices <- visOmopResults::splitAdditional(incidence) |>
  distinct(incidence_start_date) |>
  pull()

incidenceYearChoices <- incidenceYearChoices[incidenceYearChoices != "overall"]
incidenceYearChoices <- setNames(incidenceYearChoices, stringr::str_extract(incidenceYearChoices, "^[0-9]+"))

incidenceUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    fluidRow(
      h3("Incidence estimates"),
      p("Incidence estimates are shown below, please select configuration to filter them:"),
      fluidRow(
        column(2, pickerInput(ns("cdm"), "CDM name", choices = unique(incidence$cdm_name), selected = unique(incidence$cdm_name), multiple = T, options = opt)),
        column(2, pickerInput(ns("outcome"), "Outcome", choices = incidenceOutcomes, selected = "aml", multiple = T, options = opt)),
        column(2, pickerInput(ns("age_group"), "Age group", choices = unique(settings(incidence)$denominator_age_group), selected = unique(settings(incidence)$denominator_age_group), multiple = T, options = opt)),
        column(2, pickerInput(ns("sex"), "Sex", choices = unique(settings(incidence)$denominator_sex), selected = "Both", multiple = T, options = opt)),
        column(2, pickerInput(ns("interval"), "Interval", choices = c("years", "overall"), selected = "years", multiple = F, options = opt)),
        column(2, pickerInput(ns("years"), "Years", choices = incidenceYearChoices, selected = incidenceYearChoices, multiple = T, options = opt))
      ),
      tabsetPanel(
        id = ns("tabsetPanel"),
        type = "tabs",
        tabPanel(
          "Table of estimates",
          uiOutput(ns("report_table")) |> withSpinner(type = 6),
          h4("Download table"),
          downloadButton(ns("download_table"), "Download table (.docx)")
        ),
        tabPanel(
          "Plot of estimates",
          p("Plotting options"),
          fluidRow(
            column(3, selectInput(ns("plot_facet"), "Facet by",
                                  choices = c("cdm_name", "denominator_age_group", "denominator_sex", "outcome_cohort_name", "None")
            )),
            column(3, selectInput(ns("plot_colour"), "Colour by",
                                  choices = c("denominator_age_group", "cdm_name", "denominator_sex", "outcome_cohort_name", "None")
            )),
            column(3, selectInput(ns("plot_ribbon"), "Ribbon", choices = c(FALSE, TRUE)))
          ),
          plotlyOutput(ns("incidence_plot"), height = "600px") |> withSpinner(type = 6),
          h4("Download figure"),
          fluidRow(
            column(2, textInput(ns("download_height"), "Height (cm)", 10)),
            column(2, textInput(ns("download_width"), "Width (cm)", 20)),
            column(3, textInput(ns("download_dpi"), "Resolution (dpi)", 300))
          ),
          downloadButton(ns("download_plot"), "Download plot")
        ),
        tabPanel(
          "Attrition",
          uiOutput(ns("attrition_table")) |> withSpinner(type = 6),
          h4("Download attrition table"),
          downloadButton(ns("download_attrition_table"), "Download attrition table (.docx)")
        )
      )
    )
  )
}

# Incidence server
incidenceServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    filtered_data <- reactive({
      req(input$cdm, input$age_group, input$sex, input$interval)
      incidence %>%
        filter(
          cdm_name %in% input$cdm,
        ) |>
        visOmopResults::filterSettings(
          denominator_age_group %in% input$age_group,
          denominator_sex %in% input$sex
        ) %>%
        visOmopResults::filterGroup(outcome_cohort_name %in% input$outcome) %>%
        {if (input$interval == "years") {
          visOmopResults::filterAdditional(.,
                                           incidence_start_date %in% input$years,
                                           analysis_interval %in% input$interval)
        } else {
          visOmopResults::filterAdditional(., analysis_interval %in% input$interval)
        }
    }
    })

    # Table
    table_gt <- reactive({
      IncidencePrevalence::tableIncidence(
        filtered_data(),
        type = "gt",
        header = c("estimate_name"),
        groupColumn = c("cdm_name", "outcome_cohort_name"),
        settingsColumn = c("denominator_age_group", "denominator_sex"),
        hide = c("denominator_cohort_name")
      )
    })

    output$report_table <- renderUI({
      table_gt()
    })

    # Download table as docx
    output$download_table <- downloadHandler(
      filename = function() {
        "incidenceEstimatesTable.docx"
      },
      content = function(file) {
        gt_tbl <- table_gt()
        # gtsave will auto-detect extension and use gt::as_word()
        gtsave(gt_tbl, file)
      }
    )

    # Attrition Table
    attrition_gt <- reactive({
      req(input$cdm, input$age_group, input$sex)
      incidence %>%
        filter(cdm_name %in% input$cdm) |>
        visOmopResults::filterSettings(
          denominator_age_group %in% input$age_group,
          denominator_sex %in% input$sex
        )  %>%
        tableIncidenceAttrition(
          type = "gt",
          header = c("variable_name"),
          groupColumn = c("cdm_name"),
          settingsColumn = c("denominator_age_group", "denominator_sex", "denominator_days_prior_observation"),
          hide = c("denominator_cohort_name", "estimate_name", "reason_id", "variable_level")
        )
    })

    output$attrition_table <- renderUI({
      attrition_gt()
    })

    output$download_attrition_table <- downloadHandler(
      filename = function() {
        "incidenceAttritionTable.docx"
      },
      content = function(file) {
        gt_tbl <- attrition_gt()
        gtsave(gt_tbl, file)
      }
    )

    # Plot
    plot_incidence <- reactive({
      df <- filtered_data()
      validate(need(nrow(df) > 0, "No results for selected inputs"))

      attr(df, "settings") <- settings(df) |>
        mutate(denominator_age_group = factor(denominator_age_group,
                                              levels = c("0 to 17","18 to 150","18 to 39","40 to 59","60 to 79","80 to 150","0 to 150")))

      IncidencePrevalence::plotIncidence(
        df,
        x = "incidence_start_date",
        y = "incidence_100000_pys",
        line = TRUE,
        point = TRUE,
        ribbon = as.logical(input$plot_ribbon),
        ymin = "incidence_100000_pys_95CI_lower",
        ymax = "incidence_100000_pys_95CI_upper",
        facet = if (input$plot_facet != "None") input$plot_facet else NULL,
        colour = if (input$plot_colour != "None") input$plot_colour else NULL
      ) +
        ggtitle("Incidence estimates") +
        geom_line() +
        theme(plot.title = element_text(hjust = 0.5),
              axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
        guides(fill = "none")
    })

    output$incidence_plot <- renderPlotly({
      if (input$interval == "years") {
        ggplotly(plot_incidence())
      } else {
        p <- ggplot() +
          annotate("text", x = 0.5, y = 0.5, label = "No plot available when interval = 'overall'", size = 6) +
          theme_void()
        ggplotly(p)
      }
    })

    # Download
    output$download_plot <- downloadHandler(
      filename = function() "incidenceEstimatesPlot.png",
      content = function(file) {
        ggsave(
          filename = file,
          plot = plot_incidence(),
          width = as.numeric(input$download_width),
          height = as.numeric(input$download_height),
          dpi = as.numeric(input$download_dpi),
          units = "cm"
        )
      }
    )
  })
}

# -----------------------------------------------------------------------------
# Background tab module
# -----------------------------------------------------------------------------

backgroundUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    fluidRow(
      column(
        width = 12,
        card(
          card_header("Background"),
          uiOutput(ns("background_md"))
        )
      )
    )
  )
}

backgroundServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$background_md <- renderUI({
      # Read the markdown file and render as HTML
      md_file <- "background.md"
      if (file.exists(md_file)) {
        includeMarkdown(md_file)
      } else {
        HTML("<p><em>background.md file not found.</em></p>")
      }
    })
  })
}

# -----------------------------------------------------------------------------
# Databases tab module
# -----------------------------------------------------------------------------

databasesUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    fluidRow(
      div(
        style = "overflow-x: auto;",
        DTOutput(ns("table"))
      )
    ),
    fluidRow(
      column(12,
             downloadButton(ns("download"), "Download CSV")
      )
    )
  )
}

databasesServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$table <- renderDT({
      datatable(dbinfo, options = list(pageLength = 10, scrollX = TRUE))
    })

    output$download <- downloadHandler(
      filename = function() {
        "dbinfo.csv"
      },
      content = function(file) {
        write.csv(dbinfo, file, row.names = FALSE)
      }
    )
  })
}

# -----------------------------------------------------------------------------
# Sidebar and tab layout
# -----------------------------------------------------------------------------

conditionalTabs <- function(...) {
  items <- list(...)
  items[!vapply(items, is.null, logical(1))]
}

has_ded <- !is.null(dedData)
has_md  <- !is.null(measurementDiagnostics)

sidebar_items <- conditionalTabs(
  menuItem("Background", tabName = "background", icon = icon("info-circle")),
  menuItem("Databases", tabName = "databases", icon = icon("database")),
  menuItem("Incidence", tabName = "incidence", icon = icon("chart-line"))
)

tab_items <- conditionalTabs(
  tabItem("background", backgroundUI("background")),
  tabItem("databases", databasesUI("databases")),
  tabItem("incidence", incidenceUI("incidence")),
)

# -----------------------------------------------------------------------------
# App UI and server (required for runApp() and package tests)
# -----------------------------------------------------------------------------

ui <- dashboardPage(
  dashboardHeader(title = "Example Study"),

  dashboardSidebar(
    do.call(sidebarMenu, sidebar_items)
  ),

  dashboardBody(
    do.call(tabItems, tab_items)
  )
)

server <- function(input, output, session) {
  backgroundServer("background")
  databasesServer("databases")
  demographicsServer("demographics")
  cohortAttritionServer("cohortAttrition")
  incidenceServer("incidence")
  comorbiditiesServer("comorbidities")
  priorHistoryServer("priorHistory")
  lsServer("ls")
  whoServer("who")
  survivalServer("survival")
  treatmentPatternsServer("treatmentPatterns")
  dedServer("ded", dedData)
  measurementDiagnosticsServer("md")
}



