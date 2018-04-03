shinyServer(function(input, output) {
  stored.file.path <- reactive({
    xlfile <- input$xlfile
    if(is.null(xlfile)) {
      return(NULL)      
    }
    inputfile.name <- input$xlfile$datapath
    from.basename <- input$xlfile$name
    stored.file.path <- store.file(inputfile.name, from.basename)
    return(stored.file.path)
  })
  
  output$contents <- renderText({
    stored.file.path()
  })
  output$sheet_names = renderUI({
    selectInput("sheet_names", "select", choices = get.sheet.names(stored.file.path()))
  })
  observeEvent(input$submit, {
    write.sheet.as.tsv(stored.file.path(), 'FileMetaData')
    write.sheet.as.tsv(stored.file.path(), 'DataSheet', input$column_names_row)
    file.column.names <- get.column.names('DataSheet.tsv')
    output$column_names <- renderTable(file.column.names)
    add.full.excel.path.to.metadata(input$xlfile$datapath)
    load.data.to.pg('FileMetaData.tsv')
    load.data.to.pg('DataSheet.tsv')
    transfer.data.to.tables()
    output$is_loaded <- renderText({'Loaded!'})
  })
})
