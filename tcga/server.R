library(shiny)
library(DBI)

createSqliteDb <- function(sqlite.db.path) {
  sqlite.conn <- dbConnect(RSQLite::SQLite(), sqlite.db.path)
  return(sqlite.conn)
}
sqlite.conn <- createSqliteDb('gdac_tcga_data.db')
shinyServer(function(input, output) {
  statement <- reactive({
    sprintf("SELECT coreff.gene_a, coreff.gene_b, coreff.corr_coeff, cc.tcga_cancer_code, cc.full_cancer_name  FROM tcga_gene_corr_coeffs coreff JOIN tcga_cancer_codes cc ON coreff.tcga_cancer_code = cc.tcga_cancer_code WHERE gene_a = '%s' AND gene_b = '%s' ORDER BY ABS(corr_coeff)", input$gene.a, input$gene.b)
  })
  output$result <- renderTable(dbFetch(dbSendQuery(sqlite.conn, statement=statement()), n=1000))
})
