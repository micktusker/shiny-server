shinyServer(function(input, output) {
  statement <- reactive({
    sql <- "SELECT * FROM lookups.tcga_cancer_codes"
    rs <- dbSendQuery(pg.conn, sql)
    df <- data.frame(dbFetch(rs))
    dbClearResult(rs)
    return(df)
  })
  output$result <- renderTable(statement())
})