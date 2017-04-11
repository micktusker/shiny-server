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
    cd3.concs <- unique(df$cd3_concentration)
    antibody.concs <- unique(df$antibody_concentration)
    tagList(
      selectInput('donor_day_list', label = "Select donor day", choices = donor.day.vals, multiple = TRUE),
      selectInput('antibody_id_list', label = "Select antibody ID", choices = antibody.ids, multiple = TRUE),
      selectInput('cd3_concs_list', label = "Select CD3 concentrations", choices = cd3.concs, multiple = TRUE),
      selectInput('antibody_concs_list', label = "Select antibody concentrations", choices = antibody.concs, multiple = TRUE)
    )
  })
  donor.day <- reactive({input$donor_day_list})
  antibody.id <- reactive(input$antibody_id_list)
  cd3.conc <- reactive(input$cd3_concs_list)
  antibody.conc <- reactive(input$antibody_concs_list)
  observeEvent(input$subset, {
    plot.title.value <- plot.title()
    df <- get.pan.tcell.data(experiment.name(), data.column())
    df.subset <- df[df$donor_day %in% donor.day() & df$antibody_id %in% antibody.id() & df$cd3_concentration %in% cd3.conc() & df$antibody_concentration %in% antibody.conc(),]
    output$result <- DT::renderDataTable(df.subset)
    facet1 <- ggplot(df.subset, aes(x=sample_identifier, y=replicates_avg, fill=antibody_id)) + geom_bar(stat="identity") + ggtitle(plot.title.value) + theme(axis.text.x = element_text(angle = 90, vjust=0.5, hjust=0)) + facet_grid(donor_day~.)
    output$ggbarplotfacet1 <- renderPlot(facet1)
    facet2 <- ggplot(df.subset, aes(x=sample_identifier, y=replicates_avg)) + geom_bar(stat="identity") + theme(axis.text.x = element_text(size = 6, angle = 90, vjust=0.5, hjust=0)) + facet_grid(donor_day~antibody_id)
    output$ggbarplotfacet2 <- renderPlot(facet2)
  })
})