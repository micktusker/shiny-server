library(shiny)
library(DBI)

createSqliteDb <- function(sqlite.db.path) {
  sqlite.conn <- dbConnect(RSQLite::SQLite(), sqlite.db.path)
  return(sqlite.conn)
}
# Need to add the path to an environment variable in ".Renviron".
# See: http://stackoverflow.com/questions/12291418/how-can-i-make-r-read-my-environmental-variables
sqlite.db.path <- Sys.getenv('DISGENET_SQLITE_DB_PATH')
sqlite.conn <- createSqliteDb(sqlite.db.path)
shinyServer(function(input, output) {
  statement <- reactive({
    sprintf("SELECT * FROM vw_genes_diseases WHERE geneName = '%s'", input$gene.name)
  })
  output$result <- renderTable(dbFetch(dbSendQuery(sqlite.conn, statement=statement()), n=1000))
})