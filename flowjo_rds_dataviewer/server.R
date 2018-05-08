server <- function(input, output, session) {
  output$rds_files<-renderUI({
    selectInput("rds_files", "Select RDS Files To Process", choices=getRdsFiles(), selected=(getRdsFiles())[1], multiple = TRUE)
  })
  
  observeEvent(input$btn_plot, {
    output$selected_files <- renderText(input$rds_files)
    fullTable <- processRdsFiles(input$rds_files)
    simplePlot <- getSimplePlot(fullTable)
    output$simple_plot <- renderPlot(simplePlot)
  })
  
  observeEvent(input$btn_table, {
    output$selected_files <- renderText(input$rds_files)
    fullTable <- processRdsFiles(input$rds_files)
    output$full_table = DT::renderDataTable({fullTable})
  })
}