library(shiny)


fluidPage(
  titlePanel("Use readxl"),
  sidebarLayout(
    sidebarPanel(
      fileInput('xlfile', 'Choose xlsx file',
                accept = c(".xlsx")
      ),
      uiOutput(c("sheet_names")),
      actionButton("submit", "Submit", class = "btn-primary")
    ),
    mainPanel(
      textOutput('contents')) #, uiOutput(c("sheet_names"))
  )
)