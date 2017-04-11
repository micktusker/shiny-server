library(shiny)
shinyUI(fluidPage(
  titlePanel("Pan T Cell Assay"),
  
  fluidRow(
    selectInput("data_column", "Select a data column", choice = get.data.columns()),
    selectInput("experiment_name", "Select an experiment name", choice = get.experiments()),
    textInput("plot_title", "Set Plot Title",  ""),
    actionButton("submit", "Submit", class = "btn-primary"),
    uiOutput("dynamicFilters"),
    actionButton("subset", "Subset", class = "btn-primary")
  ),
  br(),
  mainPanel(plotOutput("ggbarplotfacet1")),
  mainPanel(plotOutput("ggbarplotfacet2")),
  mainPanel(DT::dataTableOutput("result"))
))