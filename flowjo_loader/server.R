shinyServer(function(input, output) {
  storedFilePath <- reactive({
    rdsFile <- input$rdsFile
    if(is.null(rdsFile)) {
      return(NULL)      
    }
    inputFileName <- input$rdsFile$datapath
    fromBasename <- input$rdsFile$name
    storedFilePath <- storeFile(inputFileName, fromBasename)
    return(storedFilePath)
  })
  
  output$contents <- renderText({
    storedFilePath()
  })
})
