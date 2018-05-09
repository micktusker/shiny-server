server <- function(input, output, session) {
  output$rds_files<-renderUI({
    selectInput("rds_files", "Select RDS Files To Process", choices=getRdsFiles(), selected = NULL, multiple = TRUE)
  })
  
  observeEvent(input$btn_table, {
    output$selected_files <- renderText(input$rds_files)
    fullTable <- getFullTable(input$rds_files)
    output$full_table = DT::renderDataTable({fullTable})
    output$population_names <- renderUI({
      selectInput("population_names", "Select Populations", choices = getPopulationNames(fullTable), selected = NULL, multiple = TRUE)
    })
    output$sample_names <- renderUI({
      selectInput("sample_names", "Select Samples", choices = getSampleNames(fullTable), selected = NULL, multiple = TRUE)
    })
  })
  
  observeEvent(input$btn_plot, {
    fullTable <- getFullTable(input$rds_files)
    selectedPopulationNames <- input$population_names
    selectedSampleNames <- input$sample_names
    plotAndSummaryList <- getPlotAndSummaryList(fullTable, populationNames = selectedPopulationNames, sampleNames = selectedSampleNames)
    output$simple_plot <- renderPlot(plotAndSummaryList$plot)
    output$summary_table <- DT::renderDataTable({plotAndSummaryList$summary_table})
  })
  
}