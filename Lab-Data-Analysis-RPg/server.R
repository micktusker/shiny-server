shinyServer(function(input, output) {
  data.column <- reactive({input$data_column})
  experiment.name <- reactive({input$experiment_name})
  source.file.description <- reactive({input$source_file_description})
  observeEvent(input$submit, {
      df <- get.pan.tcell.data(data.column(), experiment.name(), source.file.description())
      output$result <- DT::renderDataTable(df)
      output$barplot <- renderPlot(barplot(df$replicates_avg, names.arg = df$sample_identifier, las = 2, cex.names=0.3, space = 0))
  })
})