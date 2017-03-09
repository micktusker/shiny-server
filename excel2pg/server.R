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
    load.sheet.to.postgres(stored.file.path(), input$sheet_names)
    showNotification("Excel Sheet Loader", action = a(href = "javascript:location.reload();", "Sheet Loaded!"))
  })
})
