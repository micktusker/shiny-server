library(shiny)

shinyUI(fluidPage(
  textInput("GeneA", "Enter gene A:", 'CD38'),
  textInput("GeneB", "Enter gene B:", 'LAX1'),
  textInput("TCGACode", "Enter TCGA Code:", 'LUAD'),
  plotOutput("plotter"),
  tableOutput("summary"),
  tableOutput("tbl")
))
