library(shiny)
shinyUI(fluidPage(
  
  # Application title
  headerPanel("Display Correleation Coefficient Data for Gene v CD38"),
  
  fluidRow(
    textInput('gene.name','Gene Name')
  ),
  submitButton(text = "Submit", icon = NULL),
  mainPanel(
    tableOutput("result")
  )
  
))
