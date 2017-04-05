library(ggplot2)

shinyServer(function(input, output) {
  data.column <- reactive({input$data_column})
  experiment.name <- reactive({input$experiment_name})
  plot.title <- reactive({input$plot_title})
  observeEvent(input$submit, {
      df <- get.pan.tcell.data(experiment.name(), data.column())
      output$result <- DT::renderDataTable(df)
      output$barplot <- renderPlot(barplot(df$replicates_avg, main = plot.title(), names.arg = df$sample_identifier, las = 2, cex.names=0.3, space = 0))
      output$ggbarplot <- renderPlot(ggplot(df, aes(x=sample_identifier, y=replicates_avg, fill=antibody_id)) + geom_bar(stat="identity"))
})
  output$dynamicFilters <- renderUI({
    df <- get.pan.tcell.data(experiment.name(), data.column())
    donor.day.vals <- unique(df$donor_day)
    antibody.ids <- unique(df$antibody_id)
    tagList(
      selectInput('donor_day_list', label = "Select donor day", choices = donor.day.vals, multiple = TRUE),
      selectInput('antibody_id_list', label = "Select antibody ID", choices = antibody.ids, multiple = TRUE)
    )
  })
  donor.day <- reactive({input$donor_day_list})
  antibody.id <- reactive(input$antibody_id_list)
  observeEvent(input$subset, {
    #print(donor.day())
    df <- get.pan.tcell.data(experiment.name(), data.column())
    #print(names(df))
    df.subset <- df[df$donor_day %in% donor.day() & df$antibody_id %in% antibody.id(),]
    output$result <- DT::renderDataTable(df.subset)
    output$barplot <- renderPlot(barplot(df.subset$replicates_avg, main = plot.title(), names.arg = df.subset$sample_identifier, las = 2, cex.names=0.5, space = 0, xpd=TRUE, srt = 45))
    output$ggbarplot <- renderPlot(ggplot(df.subset, aes(x=sample_identifier, y=replicates_avg, fill=antibody_id)) + geom_bar(stat="identity"))
    output$ggbarplotfacet1 <- renderPlot(ggplot(df.subset, aes(x=sample_identifier, y=replicates_avg, fill=antibody_id)) + geom_bar(stat="identity") + facet_grid(donor_day~.))
    output$ggbarplotfacet2 <- renderPlot(ggplot(df.subset, aes(x=sample_identifier, y=replicates_avg)) + geom_bar(stat="identity") + facet_grid(donor_day~antibody_id))
  })
})