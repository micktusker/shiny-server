library(ggplot2)
library(dplyr)
library(plotly)

# Hard coded data will need to be removed
# theData <- read.csv("TSK01_vitro_025-cd4_percent_cd38.csv")

shinyServer(function(input, output, session) {
  
  # Create the data object when the submit button is pressed
  pan.tcell.data <- eventReactive(input$submit,{
    
    # This will need changing back when pulling live from database
    get.pan.tcell.data(input$experiment_name, input$datatype_column_name)
  })
  
  panCell.Subset <- eventReactive(input$subset, {
    
    #Check inputs before running plot
    validate(need(input$donor_day_list != "",
                  "Please select a donor day before plotting"))
    
    # Call the reactive data
    panSub <- pan.tcell.data() 
  
    # Filter the data dependant on the values selected in the subset inputs
    panSub <- panSub %>% 
      dplyr::filter(donor_day %in% input$donor_day_list, 
             antibody_id %in% input$antibody_id_list,
             cd3_concentration %in% input$cd3_concs_list,
             antibody_concentration %in% input$antibody_concs_list)
    return(panSub)
  })
  
  # Below section of code is an example of dynamically updating a select input choices
  observeEvent(input$submit, {
    panData <- pan.tcell.data()  #get.pan.tcell.data(experiment.name(), data.column())
    updateSelectInput(session, 'donor_day_list', choices = unique(panData$donor_day))
    
  })
  
  output$datatype_column_name <- renderUI({
    choices <- get.datatype.column.names.for.experiment(input$experiment_name)
    selectInput("datatype_column_name", "Select a data type", choices = choices)
  })
  
  
  # observeEvent(input$experiment_name,{
  #   print(input$experiment_name)
  #   choices <- get.datatype.column.names.for.experiment('TSK01_vitro_047')
  #   updateSelectInput(session, "datatype_column_name", choices = choices[,1])
  # })
  
  observeEvent(input$donor_day_list, {
    panData <- pan.tcell.data() 
    
    ii <- which(panData$donor_day %in% input$donor_day_list)
    choicesAntibody <- unique(as.character(panData$antibody_id)[ii])
    
    updateSelectInput(session, 'antibody_id_list', choices = choicesAntibody)
    updateSelectInput(session, 'cd3_concs_list', choices = unique(panData$cd3_concentration))
    updateSelectInput(session, 'antibody_concs_list', choices =  unique(panData$antibody_concentration))
  })
  
  output$subsetResult <- DT::renderDataTable({
    #Output the subsetted data to datatable
    DT::datatable(panCell.Subset())
  })
  
  #Create the reactive plot object. This can then be called in the dashboard and downloaded
  # Plot is dependant on panCell.Subset() which is in turn dependant on the subset button
  thePlot <- reactive({
    
    title <- ifelse(input$errorBars,
                    "Replicates average +/- SD by Antibody ID for each donor day",
                    "Replicates average by Antibody ID for each donor day")

    ##TO DO: replace hardcoded columns with shiny inputs
    facetPlot <- ggplot(data = panCell.Subset(), 
                     aes(x = antibody_id, y = replicates_avg, fill = donor_day)) +
      geom_bar(stat="summary", fun.y = "mean", position = position_dodge(0.9)) +
      theme(axis.text.x = element_text(angle = 75, vjust=0.5, hjust=0.4)) +
      ggtitle(input$plot_title, subtitle = title) 
     
    
    #Include error bars in graphic
    if(input$errorBars){
      facetPlot <- facetPlot +
        stat_summary(  
          fun.ymin = function(x)(mean(x,  na.rm=TRUE) - sd(x,  na.rm=TRUE)), 
          fun.ymax = function(x)(mean(x,  na.rm=TRUE) + sd(x,  na.rm=TRUE)),
          fun.y = mean, geom = "errorbar", position = position_dodge(0.9))
    }
    
    # Add points to graphic. Alpha to make transparent.
    if(input$withPoint){
      facetPlot <- facetPlot + geom_point(alpha = 1/5, position = position_dodge(0.9))
    }
    
    #Facet by antibody or CD3 or both
    if(!is.null(input$facetBy)){
      #Create the facet formula
      if(length(input$facetBy) == 1){
        formulaPlot <- paste(" ~ ", input$facetBy[1])
      } else{
        formulaPlot <- paste(input$facetBy[1], "~", input$facetBy[2])
      }
  
      #Add formula to facet
      facetPlot <- facetPlot + 
        facet_wrap(as.formula(formulaPlot), strip.position = "bottom", scales = "free_x") #as.formula(formulaPlot)
    }

    #Return the plot object
    return(facetPlot)
    
    
  })
  output$ggbarplotFacet <- renderPlot({
    thePlot()
    })
  
 interactionPlot <- reactive({
   # build graph with ggplot syntax
   interaction <- ggplot(data = panCell.Subset(), 
                         aes(x = interaction(antibody_id, cd3_concentration, antibody_concentration), y = replicates_avg, fill = donor_day)) +
     geom_bar(stat="summary", fun.y = "mean", position = position_dodge(0.9)) +
     theme(axis.text.x = element_text(angle = 75, vjust=0.5, hjust=0.4)) +
     stat_summary(  
       fun.ymin = function(x)(mean(x,  na.rm=TRUE) - sd(x,  na.rm=TRUE)), 
       fun.ymax = function(x)(mean(x,  na.rm=TRUE) + sd(x,  na.rm=TRUE)),
       fun.y = mean, geom = "errorbar", position = position_dodge(0.9)) +
     ggtitle(input$plot_title) +  
     geom_point(alpha = 1/5) #geom_point(alpha = 1/5, position = position_dodge(0.9))
   

   #Return the plotly object
   l <- ggplotly(interaction)%>% 
     layout(margin = list(b = 160), xaxis = list(tickangle = -75)) # Prevents long axis labels overlapping with axis title

   # # Code below stops the plotly object appearing small. This is a known issue with the package
   l$x$layout$width <- NULL
   l$x$layout$height <- NULL
   l$width <- NULL
   l$height <- NULL
   l
 })
  
  output$interactionPlot <- renderPlotly({
    interactionPlot()
  })
  
  
  # Download handler for the csv file
  output$csv = downloadHandler('tableOutput.csv', content = function(file) {
    write.csv(pan.tcell.data(), file, row.names = FALSE)
  })
  
  #Download handler for the plot (pdf)
  output$plotDownload <- downloadHandler(
    filename =  paste(Sys.Date(), "_barPlot.pdf"),
    content <- function(file){
      
      pdf(file = file)
      print(thePlot())
      dev.off()
      
    }, contentType = "image/pdf")

})
