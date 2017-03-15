shinyServer(function(input, output) {
  statement <- reactive({
    sql <- "SELECT * FROM stored_data.pan_tcell_facs_data"
    rs <- dbSendQuery(pg.conn, sql)
    df <- data.frame(dbFetch(rs))
    dbClearResult(rs)
    return(df)
  })
  output$result <- renderTable(statement())
})