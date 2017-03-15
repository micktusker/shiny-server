library(shiny)
shinyUI(fluidPage(
  
  # Application title
  headerPanel("Display TCGA Cancer Codes"),
  mainPanel(
    tableOutput("result")
  )
  
))