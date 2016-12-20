library(shiny)
library(DBI)

createSqliteDb <- function(sqlite.db.path) {
  sqlite.conn <- dbConnect(RSQLite::SQLite(), sqlite.db.path)
  return(sqlite.conn)
}
sqlite.conn <- createSqliteDb('gdac_tcga_data.db')
shinyServer(function(input, output) {
  statement <- reactive({
    sprintf("SELECT * FROM correlation_coefficients WHERE gene_b = '%s' ORDER BY corr_coeff", input$gene.name)
  })
  output$result <- renderTable(dbFetch(dbSendQuery(sqlite.conn, statement=statement()), n=1000))
})
