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
    output$donor_id <- renderUI({
      selectInput("donor_id", "Select a Donor", choices = getDonorIDs(fullTable), selected = NULL, multiple = FALSE)
    })
  })
  
  observeEvent(input$btn_plot, {
    fullTable <- getFullTable(input$rds_files)
    selectedPopulationNames <- input$population_names
    selectedSampleNames <- input$sample_names
    selectedDonorID <- input$donor_id
    plotAndSummaryList <- getPlotAndSummaryList(fullTable, populationNames = selectedPopulationNames, sampleNames = selectedSampleNames)
    output$simple_plot <- renderPlot(plotAndSummaryList$plot)
    output$summary_table1 <- DT::renderDataTable({plotAndSummaryList$summary_table})
    stackedPlotAndSummaryList <- getStackedPlot(fullTable, populationNames = selectedPopulationNames, donorID = selectedDonorID)
    output$stacked_plot <- renderPlot(stackedPlotAndSummaryList$plot)
    output$summary_table2 <- renderPlot(stackedPlotAndSummaryList$summary_table)
  })
  
}