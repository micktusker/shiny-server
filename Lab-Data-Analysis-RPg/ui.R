library(shiny)
shinyUI(fluidPage(
  titlePanel("FACS Assays"),
  
  fluidRow(
    selectInput("assay_type", "Select an assay type", choices = c("Pan T Cell")),
    selectInput("experiment_name", "Select an experiment name", choices = get.experiments()),
    selectInput("datatype_column_name", "Select a data type", choices = get.datatype.column.names()),
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
