library(shiny)
fluidPage(
  titlePanel("FlowJo Analysis"),
  sidebarPanel(
    uiOutput("rds_files"),
    actionButton("btn_table", "Generate Table"),
    uiOutput("population_names"),
    uiOutput("sample_names"),
    uiOutput("donor_id"),
    actionButton("btn_plot", "Generate Plots")
  ),
  mainPanel(
    tabsetPanel(type = "tabs",
                tabPanel("Simple Plot",
                         plotOutput("simple_plot"),
                         DT::dataTableOutput("summary_table1")),
                tabPanel("Stacked Plot",
                         plotOutput("stacked_plot"),
                         DT::dataTableOutput("summary_table2")),
                tabPanel("Full Data Table",
                         DT::dataTableOutput("full_table"))
    )
  )
)