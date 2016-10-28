library(shiny)
shinyUI(fluidPage(
  
  # Application title
  headerPanel("DisGeNET Display for Chosen Gene"),
  
  fluidRow(
    textInput('gene.name','Gene Name')
  ),
  submitButton(text = "Submit", icon = NULL),
  mainPanel(
    tableOutput("result")
  )
  
))