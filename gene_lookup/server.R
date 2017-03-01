library(shiny)
library(DBI)

createSqliteDb <- function(sqlite.db.path) {
  sqlite.conn <- dbConnect(RSQLite::SQLite(), sqlite.db.path)
  return(sqlite.conn)
}
sqlite.conn <- createSqliteDb('hgnc_genes.db')
shinyServer(function(input, output, session) {
  result <- reactive({
    if(nchar(input$gene_identifier) < 1) {
      return(NULL)
    }
    isolate({
      input$gene_identifier
      qry <- "SELECT
                hg.symbol,
                name,
                locus_group,
                location,
                entrez_id,
                ensembl_gene_id,
                uniprot_ids
              FROM
                hgnc_genes hg 
                JOIN gene_names_lookup lu ON hg.hgnc_id = lu.hgnc_id
              WHERE 
                lu.gene_identifier = UPPER(:gene_identifier)"
      rs <- dbSendQuery(sqlite.conn, qry)
      dbBind(rs, params = list(gene_identifier = input$gene_identifier))
      df <- data.frame(dbFetch(rs))
      dbClearResult(rs)
      return(df)
     })
    session$onSessionEnded(function() {
      dbDisconnect(sqlite.conn)
    })
  })
  output$result <- renderTable({result()})
})
