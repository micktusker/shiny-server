library(shiny)

function(input, output) {
  rows <- reactive({
    if(is.null(input$filename)) {
      return(NULL)
    }
    inputfile.name <- input$filename$datapath
    from.basename <- input$filename$name
    stored.file.path <- store.file(inputfile.name, from.basename)
    return(read.delim2(stored.file.path, header = input$header, stringsAsFactors = TRUE))
  })
  output$contents <- renderTable({
    rows()
  })
}
