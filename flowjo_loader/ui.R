library(shiny)

fluidPage(
  titlePanel("Upload RDS Files To Linux"),
  sidebarLayout(
    sidebarPanel(
      fileInput('rdsFile', 'Choose RDS file', accept = c(".rds")
      )
    ),
    mainPanel(
      textOutput('contents')) #, uiOutput(c("sheet_names"))
  )
)
