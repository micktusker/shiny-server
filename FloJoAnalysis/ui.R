library(shiny)
fluidPage(
  titlePanel("FlowJo Analysis"),
  sidebarPanel(
    uiOutput("rds_files"),
    actionButton("btn_table", "Generate Table"),
    uiOutput("panel_names"),
    uiOutput("population_names"),
    actionButton("btn_plot_subset", "Generate Plot Subset"),
    uiOutput("stack_populations"),
    uiOutput("colour_by_marker_expression"),
    uiOutput("variable_names"),
    actionButton("btn_plot", "Generate Plots")
  ),
  mainPanel(
    tabsetPanel(type = "tabs",
                tabPanel("Individuals Plots",
                         uiOutput("individual_plots")),
                tabPanel("Individuals Tables",
                         uiOutput("individual_tables")),
                tabPanel("Pooled Plot",
                         plotOutput("stacked_plot")),
                tabPanel("Pooled Table",
                         DT::dataTableOutput("pooled_table")),
                tabPanel("Full Data Table",
                         DT::dataTableOutput("full_table"))
    )
  )
)
