library(shiny)


fluidPage(
  titlePanel("Upload FACS Data to Database"),
  sidebarLayout(
    sidebarPanel(
      fileInput('xlfile', 'Choose xlsx file',
                accept = c(".xlsx")
      ),
      uiOutput(c("sheet_names")),
      numericInput("column_names_row", "Column Names Row:", value = 7),
      actionButton("submit", "Submit", class = "btn-primary")
    ),
    mainPanel(
      textOutput('contents'),
      textOutput('is_loaded'),
      tableOutput('column_names'))
  )
)