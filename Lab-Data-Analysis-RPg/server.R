### Load packages
library(ggplot2)
library(dplyr)
library(plotly)
library(purrr)

## Source helpers file
source("helpers.R")


shinyServer(function(input, output, session) {
  
  # Create a reactive value to store the subset selections
  # These can then be retained if the data type changes
  current_selection <- reactiveValues(donor = NULL, antibody = NULL, cd3 = NULL, 
                                      antiConc = NULL, dataType = NULL)

  
  # Dynamically update the data type options when selected experiment changes
  output$datatype_column_name <- renderUI({
    choices <- get.datatype.column.names.for.experiment(input$experiment_name)
    selectInput("datatype_column_name", "Select a data type", choices = choices)
  })
  
  # Create the data object when the submit button is pressed
  pan.tcell.data <- eventReactive(input$submit,{
    get.pan.tcell.data(input$experiment_name, input$datatype_column_name)
  })
  

  panCell.Subset <- eventReactive(input$run, {
    
    # Each time the run button is hit the selected values are stored
    # If the data type or experiment is changed the selected options can be retained.
    current_selection$donor <- input$donor_day_list
    current_selection$antibody <- input$antibody_id_list
    current_selection$cd3 <- input$cd3_concs_list
    current_selection$antiConc <- input$antibody_concs_list
    current_selection$dataType <- input$datatype_column_name
    
    
    # Call the reactive data
    panSub <- pan.tcell.data() 

    panSub <- panSub %>% 
      dplyr::mutate(antibody_concentration = ifelse(is.na(antibody_concentration), "NA", antibody_concentration),
                    cd3_concentration =  ifelse(is.na(cd3_concentration), "NA", cd3_concentration)) %>% 
      dplyr::filter(donor_day %in% input$donor_day_list, 
                    antibody_id %in% input$antibody_id_list,
                    cd3_concentration %in% input$cd3_concs_list,
                    antibody_concentration %in% input$antibody_concs_list) %>% 
      dplyr::mutate(antibody_concentration = as.numeric(antibody_concentration),
                    cd3_concentration =  as.numeric(cd3_concentration))
    
     return(panSub)
  })

  # Update or retain the input choices dependant on pulled data
  observeEvent(input$submit, {
    
    panData <- pan.tcell.data() 
    
    updateSelectInput(session, 'donor_day_list', 
                      choices = unique(panData$donor_day), selected = current_selection$donor )
    updateSelectInput(session, 'antibody_id_list',
                      choices = unique(panData$antibody_id), selected = current_selection$antibody)
    updateSelectInput(session, 'cd3_concs_list', 
                      choices = unique(panData$cd3_concentration), selected = current_selection$cd3)
    updateSelectInput(session, 'antibody_concs_list', 
                      choices =  unique(panData$antibody_concentration), selected =  current_selection$antiConc)
    
    showNotification(h3("Data pull sucessful! Ready for subset..."), duration = 3, type = "message")
  })
  

  #Render the UI for selecting the axis variables. Choices dependant on input data
  output$graphicAxis <- renderUI({
    box(title = "Variable Control", solidHeader = TRUE, collapsible = TRUE, 
        collapsed = TRUE, width = 10, status = "primary",
        
        selectInput("ctrlVar", "Control Variables",
                    choices = unique(pan.tcell.data()$antibody_id), 
                    selected = grep("ctrl", unique(pan.tcell.data()$antibody_id), value = TRUE, ignore.case = TRUE),
                    multiple = TRUE),
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

    experimentSplit <-  if(input$tabs == "By Donor_Day"){
      input$donor_ExperimentSplit
    } else{input$antiB_ExperimentSplit}
    

    #Outputs a list of ggplot objects, graphics split by experiment and/or antibody
    experimentToAntibody_split(data = panCell.Subset(), experiment_name = input$experiment_name,
              byExperiment = experimentSplit, errorBars = input$errorBars, xVar = input$xVar,
              responseVar = input$responseVar, subTitle = input$plot_title,
              greyScale = input$greyScale, withPoint = input$withPoint,
              facetBy = input$facetBy, xAxisAngle = input$xTextAdj, xAxisFont = input$xAxisFont,
              legendSize = input$legendSize, dataType = current_selection$dataType, controls = input$ctrlVar)
  
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
  
  
  # Dynamically render multiple graphics for each experiment
  output$donor_day <-  renderUI({
    
    plot_output_list <- lapply(seq_along(thePlot()$donorDay), function(i) {
      plotname <- paste("plotDonor", i, sep="")
      plotOutput(plotname)
    })
    # Convert the list to a tagList - this is necessary for the list of items
    # to display properly.
    do.call(tagList, plot_output_list)
  })

  
  max_plots <- 100          # Hardcoded value, maximum number of experiments & antibodies to compare between.
  
  for (i in 1:max_plots) {
    # https://gist.github.com/wch/5436415/
    # Need local so that each item gets its own number. Without it, the value
    # of i in the renderPlot() will be the same across all instances, because
    # of when the expression is evaluated.
    
    local({
      my_i <- i
      plotname <- paste("plot", my_i, sep="")
      plotname_antiB <- paste("plotAntibody", my_i, sep="")
      plotname_donorD <- paste("plotDonor", my_i, sep="")
      
      # Render mulitple experiment plots
      output[[plotname]] <- renderPlot({
        thePlot()$experiment[[my_i]] 
        })
      # Render mulitple antibody plots
      output[[plotname_antiB]] <- renderPlot({
        thePlot()$antibody[[my_i]]
      })
      # Render mulitple donorDay plots
      output[[plotname_donorD]] <- renderPlot({
        thePlot()$donorDay[[my_i]] 
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
        #Read in logo and convert to a grid object
        img <- png::readPNG("www/tusk.png")
        logo <- grid::grobTree(grid::rasterGrob(img, x=0.3, hjust=1))
        
        pdf(file = file)    
         # Map logo to each page of the pdf
          thePlot()$experiment %>%
            map(~ gridExtra::grid.arrange(gridExtra::arrangeGrob(.), logo, heights=c(9, 1)))
        dev.off()
      }else{
        
        pdf(file = file)
            thePlot()$experiment %>%
              map(~ gridExtra::grid.arrange(.))
        dev.off()
        }
      
    }, contentType = "image/pdf") 
  
  
  
  #Download handler for the antibody plots (pdf)
  output$plotDownload_AntiB <- downloadHandler(
    filename =  paste(Sys.Date(), "_antiBodies.pdf"),
    content <- function(file){
      
      if(input$downloadLogo){
        #Read in logo and convert to a grid object
        img <- png::readPNG("www/tusk.png")
        logo <- grid::grobTree(grid::rasterGrob(img, x=0.3, hjust=1))
        
        pdf(file = file)    
        # Map logo to each page of the pdf
        thePlot()$antibody %>%
          map(~ gridExtra::grid.arrange(gridExtra::arrangeGrob(.), logo, heights=c(9, 1)))
        dev.off()
        
      }else{
        
        pdf(file = file)
          thePlot()$antibody %>%
            map(~ gridExtra::grid.arrange(.))
        dev.off()
      }
    }, contentType = "image/pdf")
  
  #Download handler for the donorDay plots (pdf)
  output$plotDownload_DonorDay <- downloadHandler(
    filename =  paste(Sys.Date(), "_donorDay.pdf"),
    content <- function(file){
      
      if(input$downloadLogo){
        #Read in logo and convert to a grid object
        img <- png::readPNG("www/tusk.png")
        logo <- grid::grobTree(grid::rasterGrob(img, x=0.3, hjust=1))
        
        pdf(file = file)    
        # Map logo to each page of the pdf
        thePlot()$donorDay %>%
          map(~ gridExtra::grid.arrange(gridExtra::arrangeGrob(.), logo, heights=c(9, 1)))
        dev.off()
        
      }else{
        
        pdf(file = file)
        thePlot()$donorDay %>%
          map(~ gridExtra::grid.arrange(.))
        dev.off()
      }
    }, contentType = "image/pdf")
  
})