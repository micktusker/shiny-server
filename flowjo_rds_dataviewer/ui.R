library(shiny)
fluidPage(
  titlePanel("FlowJo Analysis"),
  sidebarPanel(
    uiOutput("rds_files"),
    actionButton("btn_table", "Generate Table"),
    uiOutput("population_names"),
    uiOutput("sample_names"),
    actionButton("btn_plot", "Generate Plot")
  ),
  mainPanel(
    tabsetPanel(type = "tabs",
                tabPanel("Full Data Table",
                         DT::dataTableOutput("full_table")),
                tabPanel("Plot",
                         plotOutput("simple_plot")),
                tabPanel("Summary",
                         DT::dataTableOutput("summary_table"))
    )
  )
)