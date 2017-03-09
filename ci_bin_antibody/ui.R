library(shiny)

fluidPage(
  titlePanel("Uploading Files"),
  sidebarLayout(
    sidebarPanel(
      fileInput('filename', 'Choose CSV File',
                accept=c('text/plain')),
      tags$hr(),
      checkboxInput('header', 'Header', TRUE)
    ),
    mainPanel(
      textOutput('selectedfile'),
      tableOutput('contents')
    )
  )
)
