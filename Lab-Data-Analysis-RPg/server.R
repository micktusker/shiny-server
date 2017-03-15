shinyServer(function(input, output) {
  statement <- reactive({
    sql <- "SELECT * FROM lookups.tcga_cancer_codes"
    df <- dbFetch(dbSendQuery(pg.conn, statement=statement()), n=1000)
    df
  })
  output$result <- renderTable(df)
})