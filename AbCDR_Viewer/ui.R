library(shiny)
fluidPage(
  titlePanel("Antibody CDR Analysis"),
  textAreaInput("aa_seq", "Paste Sequence", width = "1000px", height = "100px"),
  submitButton(text = "Submit", icon = NULL),
  mainPanel(
    tableOutput("result"),
    htmlOutput("aa_seq_formatted"))
)
