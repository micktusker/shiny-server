library(shiny)
shinyUI(fluidPage(
  
  # Application title
  headerPanel("Display All Loaded Data"),
  mainPanel(
    tableOutput("result")
  )
  
))