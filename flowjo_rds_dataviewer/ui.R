library(shiny)

fluidPage(
  uiOutput("rds_files"),
  actionButton("btn_plot", "Generate Plot"),
  actionButton("btn_table", "Generate Table"),
  tags$br(),
  tags$label("Output"),
  textOutput("selected_files"),
  tags$br(),
  plotOutput("simple_plot"),
  tags$br(),
  DT::dataTableOutput("full_table")
)