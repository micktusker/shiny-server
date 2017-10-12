## Load packages
library(ggplot2)
library(dplyr)
library(plotly)
library(purrr)

## Source helpers file
source("helpers.R")


shinyServer(function(input, output, session) {
  
  # Create the data object when the submit button is pressed
  pan.tcell.data <- eventReactive(input$submit,{
    
    get.pan.tcell.data(input$experiment_name, input$datatype_column_name)
    
  })
  
  panCell.Subset <- eventReactive(input$run, {
    
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
    panData <- pan.tcell.data() 
    updateSelectInput(session, 'donor_day_list', choices = unique(panData$donor_day))
    updateSelectInput(session, 'antibody_id_list', selected = "")
    updateSelectInput(session, 'cd3_concs_list', selected = "")
    updateSelectInput(session, 'antibody_concs_list', selected =  "")
    
  })
  
  #Dynamically update the data type options.
  output$datatype_column_name <- renderUI({
    choices <- get.datatype.column.names.for.experiment(input$experiment_name)
    selectInput("datatype_column_name", "Select a data type", choices = choices)
  })
  
  observeEvent(input$donor_day_list, {
    panData <- pan.tcell.data() 
    
    ii <- which(panData$donor_day %in% input$donor_day_list)
    choicesAntibody <- unique(as.character(panData$antibody_id)[ii])
    
    updateSelectInput(session, 'antibody_id_list', choices = choicesAntibody)
    updateSelectInput(session, 'cd3_concs_list', choices = unique(panData$cd3_concentration))
    updateSelectInput(session, 'antibody_concs_list', choices =  unique(panData$antibody_concentration))
  })
  
  #Render the UI for selecting the axis variables. Choices dependant on input data
  output$graphicAxis <- renderUI({
    box(title = "Variable Control", solidHeader = TRUE, collapsible = TRUE, 
        collapsed = TRUE, width = 10, status = "primary",
        
        selectInput("responseVar", "Select Response variable", 
                    choices = colnames(pan.tcell.data()), selected = "replicates_avg"),
        selectInput("xVar", "X Axis", 
                    choices = colnames(pan.tcell.data()), selected = "antibody_id")
        )
    
  })
  
  output$subsetResult <- DT::renderDataTable({
    #Output the subsetted data to datatable
    DT::datatable(panCell.Subset())
  })
  
  # # Create the reactive plot object. This can then be called in the dashboard and downloaded
  # # Plot is dependant on panCell.Subset() which is in turn dependant on the subset button
  thePlot <- reactive ({

    #Outputs a list of ggplot objects, graphics split by experiment and/or antibody
    experimentToAntibody_split(data = panCell.Subset(), experiment_name = input$experiment_name,
              byExperiment = input$intraExperiment, errorBars = input$errorBars, xVar = input$xVar,
              responseVar = input$responseVar, subTitle = input$plot_title,
              greyScale = input$greyScale, withPoint = input$withPoint,
              facetBy = input$facetBy, xAxisAngle = input$xTextAdj, xAxisFont = input$xAxisFont,
              legendSize = input$legendSize)
  
  })

 
  # Dynamically render multiple graphics for each experiment
  output$ggbarplotFacet <-  renderUI({
   
       plot_output_list <- lapply(seq_along(thePlot()$experiment), function(i) {
         plotname <- paste("plot", i, sep="")
         plotOutput(plotname)
    })
    
    # Convert the list to a tagList - this is necessary for the list of items
    # to display properly.
    do.call(tagList, plot_output_list)
  })
  

  # Dynamically render multiple graphics for each antibody
  output$antibodyFacet <-  renderUI({
    
    plot_output_list <- lapply(seq_along(thePlot()$antibody), function(i) {
      plotname <- paste("plotAntibody", i, sep="")
      plotOutput(plotname)
    })
    # Convert the list to a tagList - this is necessary for the list of items
    # to display properly.
    do.call(tagList, plot_output_list)
 
  })

  
  max_plots <- 50          # Hardcoded value, maximum number of experiments & antibodies to compare between.
  
  for (i in 1:max_plots) {
    # https://gist.github.com/wch/5436415/
    # Need local so that each item gets its own number. Without it, the value
    # of i in the renderPlot() will be the same across all instances, because
    # of when the expression is evaluated.
    
    local({
      my_i <- i
      plotname <- paste("plot", my_i, sep="")
      
      output[[plotname]] <- renderPlot({
        thePlot()$experiment[[my_i]] 
        })
    })
    }

  for (i in 1:max_plots) {

    local({
      my_i <- i
      plotname <- paste("plotAntibody", my_i, sep="")

      output[[plotname]] <- renderPlot({
         thePlot()$antibody[[my_i]]

      })
    })
  }
  

  #Create the interaction plot reactive object 
  interactionPlot <- reactive({
    interactionPlotFun(data = panCell.Subset(), responseVar = input$responseVar, 
                    plotTitle = input$plot_title, greyScale = input$greyScale, 
                    xAxisAngle = input$xTextAdj, xAxisFont = input$xAxisFont)

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
    filename =  paste(Sys.Date(), "_experiments.pdf"),
    content <- function(file){
      if(input$downloadLogo){
        img <- png::readPNG("www/tusk.png")
        logo <- grid::grobTree(grid::rasterGrob(img, x=0.3, hjust=1))
        
        
        pdf(file = file)
        for(i in seq_along(thePlot()$experiment)){
        gridExtra::grid.arrange(gridExtra::arrangeGrob(thePlot()$experiment[[i]]), logo, heights=c(9, 1))
        }
        
        dev.off()
      }else{

        pdf(file = file)
        
        for(i in seq_along(thePlot()$experiment)){
          gridExtra::grid.arrange(thePlot()$experiment[[i]])
        }

        dev.off()
      }
      
      
    }, contentType = "image/pdf") # 
  
  
  
  #Download handler for the antibody plots (pdf)
  output$plotDownloadAntiB <- downloadHandler(
    filename =  paste(Sys.Date(), "_antiBodies.pdf"),
    content <- function(file){
        pdf(file = file)
        for(i in seq_along(thePlot()$antibody)){
          gridExtra::grid.arrange(thePlot()$antibody[[i]])
        }
        dev.off()
      
    }, contentType = "image/pdf")
  
})