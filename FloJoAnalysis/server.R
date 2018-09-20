server <- function(input, output, session) {
  cachedVals <- reactiveValues(fullTable = NULL, tableList = NULL)
  
  output$rds_files<-renderUI({
    selectInput("rds_files", "Select RDS Files To Process", choices=getRdsFiles(), selected = NULL, multiple = TRUE)
  })
  
  observeEvent(input$btn_table, {
    output$selected_files <- renderText(input$rds_files)
    cachedVals$fullTable <- getFullTable(input$rds_files)
    output$full_table = DT::renderDataTable({cachedVals$fullTable})
    output$panel_names <- renderUI({
      selectInput("panel_names", "Select Panel", choices = getPanelNames(cachedVals$fullTable), selected = NULL, multiple = TRUE)
    })
    output$population_names <- renderUI({
      selectInput("population_names", "Select Populations", choices = getPopulationNames(cachedVals$fullTable), selected = NULL, multiple = TRUE)
    })
  })
  
  observeEvent(input$btn_plot_subset, {
    selectedPopulations <- input$population_names
    cachedVals$tableList <- getTableList(cachedVals$fullTable, selectedPopulations)
    # output$plot_table <- DT::renderDataTable({cachedVals$tableList})
    output$colour_by_marker_expression <- renderUI({
      checkboxInput("colour_by_marker_expression", "Colour By Marker Expression", TRUE)
    })
    output$stack_populations <- renderUI({
      checkboxInput("stack_populations", "Stack Populations?", TRUE)
    })
    output$variable_names <- renderUI({
      selectInput("variable_names", "Variable Names To Plot", choices = getVariableNames(cachedVals$tableList[[1]]), selected = NULL, multiple = FALSE)
    })    
  })
  
  observeEvent(input$btn_plot, {
    expressionParameter <- input$variable_names
    if(input$colour_by_marker_expression) {
      expressionToggle <- "y"
    } else {
      expressionToggle <- "n"
    }
    if(input$stack_populations) {
      stackToggle <- "y"
    } else {
      stackToggle <- "n"
    }
    # INDIVIDUAL PLOTS --------------------------------------------
    ##plot each donor
    myPlots <- list()
    columnNames <- names(cachedVals$tableList[[1]])
    for (i in 1:length(cachedVals$tableList)){
      local({
        i <- i
        tempSet <- as.data.frame(cachedVals$tableList[[i]])
        colnames(tempSet) <- columnNames
        stackToggle <- assign(stackToggle, ifelse(stackToggle == "y", "xLabels", "Population"))
        if(expressionToggle=="y"){
          plot <- ggplot(tempSet, aes(x=get(stackToggle), y=Count, fill=get(expressionParameter))) + geom_bar(stat="identity") +  theme(axis.text.x = element_text(angle = 45, hjust = 1))+ labs(fill=paste0(expressionParameter), title=paste0("proportions and CD25 receptor density of immune \n cell populations in ", names(cachedVals$tableList)[i])) + theme(plot.title = element_text(hjust = 0.5), axis.title.x=element_blank()) + scale_fill_gradient(low = "white", high = "darkred", limits=c(0,as.numeric(paste0(max(as.numeric(lapply(cachedVals$tableList, function(x){max(x[[expressionParameter]])})))))))
        } else if(expressionToggle=="n"){
          plot <- ggplot(tempSet, aes(x=get(stackToggle), y=Count, fill=Population)) + geom_bar(stat="identity") + theme(axis.text.x = element_text(angle = 45, hjust = 1)) + labs(title= paste0("Proportions of immune cell populations in ", names(tableList)[i])) + theme(plot.title = element_text(hjust = 0.5), axis.title.x=element_blank()) +scale_fill_brewer(palette="Set3")
        }
        myPlots[[i]] <<- plot
      })
      
    }
    plotCount <- length(myPlots)
    # Following code adapted from: https://gist.github.com/wch/5436415/
    # Insert the right number of plot output objects into the web page
    output$individual_plots <- renderUI({
      plotOutputList <- lapply(1:plotCount, function(i) {
        plotName <- paste("plot", i, sep="")
        plotOutput(plotName)#, height = 280, width = 250)
      })
      
      # Convert the list to a tagList - this is necessary for the list of items
      # to display properly.
      do.call(tagList, plotOutputList)
    })
    # Call renderPlot for each one. Plots are only actually generated when they
    # are visible on the web page.
    for (i in 1:plotCount) {
      # Need local so that each item gets its own number. Without it, the value
      # of i in the renderPlot() will be the same across all instances, because
      # of when the expression is evaluated.
      local({
        my_i <- i
        plotName <- paste("plot", my_i, sep="")
        output[[plotName]] <- renderPlot({
          myPlots[[my_i]]
        })
      })
    }
    # Build the tables
    tableCount <- length(cachedVals$tableList)
    output$individual_tables <- renderUI({
      tableOutputList <- lapply(1:tableCount, function(i) {
        tableName <- paste("table", i, sep="")
        tableOutput(tableName)
      })
      do.call(tagList, tableOutputList)
    })
    for (i in 1:tableCount) {
      local({
        my_i <- i
        tableName <- paste("table", my_i, sep="")
        output[[tableName]] <- renderTable({
          cachedVals$tableList[[my_i]]
        })
      })
    }
    # POOL PLOTS --------------------------------------------------------------
    # Mark can add this.
    indicationToggle <- "y"
    plotSet <- rbindlist(cachedVals$tableList)
    
    ##get statistics for the pooled donors
    y_variable <- as.character("Count")
    statSet <- statSetting(plotSet, "Population", y_variable)
    statSet[[y_variable]]= with(statSet,mean)
    statSet <- merge(statSet,unique.data.frame(data.frame(plotSet$Population,plotSet$xLabels)), by.x = "Population", by.y = "plotSet.Population")
    names(statSet)[7] <- "xLabels"
    stackToggle <- assign(stackToggle, ifelse(stackToggle == "y", "xLabels", "Population"))
    if(indicationToggle=="y"){
      poolPlot <- ggplot(plotSet, aes(x=get(stackToggle), y=get(y_variable), fill=Population)) + geom_bar(data=statSet,stat="identity") + theme(axis.text.x = element_text(angle = 45, hjust = 1)) +scale_fill_brewer(palette="Set3") + geom_dotplot(binaxis='y', binwidth = 1, stackdir='center') + stat_summary(fun.data=mean_sdl, fun.args = list(mult=1), geom="errorbar", color="black", width=0.2) + labs(y = paste0(y_variable), title= paste0("Proportions of immune cell populations in ")) + theme(plot.title = element_text(hjust = 0.5), axis.title.x=element_blank()) +facet_wrap(~Indication)
    } else if(indicationToggle=="n"){
      poolPlot <- ggplot(plotSet, aes(x=get(stackToggle), y=get(y_variable), fill=Population)) + geom_bar(data=statSet,stat="identity") + theme(axis.text.x = element_text(angle = 45, hjust = 1)) +scale_fill_brewer(palette="Set3") + geom_dotplot(binaxis='y', binwidth = 1, stackdir='center') + stat_summary(fun.data=mean_sdl, fun.args = list(mult=1), geom="errorbar", color="black", width=0.2) + labs(y = paste0(y_variable), title= paste0("Proportions of immune cell populations in ")) + theme(plot.title = element_text(hjust = 0.5), axis.title.x=element_blank())
    }
    output$stacked_plot <- renderPlot(poolPlot)
    output$pooled_table <- DT::renderDataTable(plotSet)
  })
}
