library(shiny)
# Define UI for application that plots random distributions 
fluidPage(
  # App title ----
  titlePanel("Antibody CDR Analysis"),
  textAreaInput("aa_seq", "Paste Sequence", width = "1000px", height = "100px"),
  submitButton(text = "Submit", icon = NULL),
  mainPanel(tableOutput("result"))
)
