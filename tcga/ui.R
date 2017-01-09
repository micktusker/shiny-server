library(shiny)

shinyUI(fluidPage(
  # Application title
  headerPanel(
    "Display All Correlation Coefficient Data for Genes CCR4, CD25, CD38 abd TNFRSF9 (CD137)"
  ),
  
  fluidRow(
    selectInput("gene.a", "Gene A",
                choices = c("CCR4", "CD25", "CD38", "TNFRSF9"))
    ,
    textInput('gene.b', 'Gene B')
  ),
  submitButton(text = "Submit", icon = NULL),
  mainPanel(tableOutput("result"))
  
))