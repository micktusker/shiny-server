library(shiny)
shinyUI(fluidPage(
  titlePanel("Gene Lookup"),
  
  fluidRow(
      textInput("gene_identifier", label = "Enter a gene identifier")
  ),
  submitButton(text = "Submit", icon = NULL),
  mainPanel(tableOutput("result"))
))