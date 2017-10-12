#' mainPlot
#'
#' @param data Plot data
#' @param errorBars Should the plot include error bars?
#' @param xVar CX variable to plot
#' @param responseVar Response varaible to plot
#' @param plotTitle Plot title
#' @param subTitle Default subtible can be overwritten in app
#' @param greyScale Should graphic be grey scale
#' @param withPoint should points be plotted on graphic?
#' @param facetBy one or more variables to facet the plot by
#' @param xAxisAngle Angle of x-axis label
#' @param xAxisFont Font size of x-axis label
#' @param legendSize adjustable font size for legend text
#'
#' @return ggplot object
#' @export
#' @description Produces the main FACs analysis graphic. 

mainPlot <- function(data, errorBars = FALSE, xVar, responseVar, plotTitle, subTitle, 
                     greyScale = FALSE, withPoint = FALSE, facetBy = NULL, 
                     xAxisAngle = 75, xAxisFont = 5, legendSize = 8){
  

  # Create the reactive plot object. This can then be called in the dashboard and downloaded
  # Plot is dependant on panCell.Subset() which is in turn dependant on the subset button

    title <- if(subTitle == ""){
      ifelse(errorBars,
                    "Replicates average +/- SD by Antibody ID for each donor day",
                    "Replicates average by Antibody ID for each donor day")
    } else{ subTitle }

   
    facetPlot <- ggplot(data = data, 
                        aes_string(x = xVar, y = responseVar, fill = "donor_day")) +
      geom_bar(stat="summary", fun.y = "mean", position = position_dodge(0.9)) +
      theme(axis.text.x = element_text(angle = xAxisAngle, hjust= 1, size = xAxisFont)) +
      guides(fill = guide_legend(label.theme = element_text(size = legendSize, angle = 0))) +
      labs(subtitle = title) +
      labs(title = plotTitle)
    
    #Make graphic grey
    if(greyScale){
      facetPlot <- facetPlot + scale_fill_grey()
    }
    
    
    #Include error bars in graphic
    if(errorBars){
      facetPlot <- facetPlot +
        stat_summary(  
          fun.ymin = function(x)(mean(x,  na.rm=TRUE) - sd(x,  na.rm=TRUE)), 
          fun.ymax = function(x)(mean(x,  na.rm=TRUE) + sd(x,  na.rm=TRUE)),
          fun.y = mean, geom = "errorbar", position = position_dodge(0.9))
    }
    
    
    # Add points to graphic. Alpha to make transparent.
    if(withPoint){
      facetPlot <- facetPlot + geom_point(alpha = 1/5, position = position_dodge(0.9))
    }
    
    #Facet by antibody or CD3 or both
    if(!is.null(facetBy)){
      #Create the facet formula
      if(length(facetBy) == 1){
        formulaPlot <- paste(" ~ ", facetBy[1])
      } else{
        formulaPlot <- paste(facetBy[1], "~", facetBy[2])
      }
      
      #Add formula to facet
      facetPlot <- facetPlot + 
        facet_wrap(as.formula(formulaPlot), strip.position = "bottom", scales = "free_x") 
    }
  
  facetPlot
  
}

#' interactionPlotFun
#'
#' @param data Plot data
#' @param responseVar Response varaible to plot
#' @param plotTitle Plot title
#' @param greyScale Should graphic be grey scale
#' @param xAxisAngle Angle of x-axis label
#' @param xAxisFont Font size of x-axis label
#'
#' @return ggplot object
#' @export
#' @description Produces the interation graphic, the repsonse variableis interative with
#'              the responseVar chosen. 
#'              The x variable is a combination of antibody_id, cd3_concentration & antibody_concentration
#' 

interactionPlotFun <- function(data, responseVar, plotTitle, greyScale = FALSE, 
                               xAxisAngle = 75, xAxisFont = 5){
  #Have to pass y variable into each geom_layer as a work around for non standard eval. with the interaction
  yVar <- responseVar
  
  # build graph with ggplot syntax
  interaction <- ggplot(data = data, 
                        aes(x = interaction(antibody_id, cd3_concentration, antibody_concentration), fill = donor_day)) +
    geom_bar(aes_string(y = yVar), stat="summary", fun.y = "mean", position = position_dodge(0.9)) +
    theme(axis.text.x = element_text(angle = xAxisAngle, hjust = 1, size = xAxisFont)) +
    stat_summary(  aes_string(y = yVar),
                   fun.ymin = function(x)(mean(x,  na.rm=TRUE) - sd(x,  na.rm=TRUE)), 
                   fun.ymax = function(x)(mean(x,  na.rm=TRUE) + sd(x,  na.rm=TRUE)),
                   fun.y = mean, geom = "errorbar", position = position_dodge(0.9)) +
    ggtitle(plotTitle) +  
    geom_point(aes_string(y = yVar),alpha = 1/5) #geom_point(alpha = 1/5, position = position_dodge(0.9))
  
  #Make graphic grey
  if(greyScale){
    interaction <- interaction + scale_fill_grey()
  }
  
  #Return the plotly object
  l <- ggplotly(interaction)%>% 
    layout(margin = list(b = 160), xaxis = list(tickangle = -(xAxisAngle))) # Prevents long axis labels overlapping with axis title
  
  # # Code below stops the plotly object appearing small. This is a known issue with the package
  l$x$layout$width <- NULL
  l$x$layout$height <- NULL
  l$width <- NULL
  l$height <- NULL
  l
}

#' experimentToAntibody_split
#'
#' @param data Plot data
#' @param experiment_name vector of experiment names
#' @param byExperiment T/F split data by experiment first?
#' @param ... arguments to be used in mainPlot()
#'
#' @return a list of ggplot objects
#' @export
#' @description Iterates of the different combination of experiments/antibodies to produce separate graphics
#' 

experimentToAntibody_split <- function(data, experiment_name, byExperiment = TRUE, ...){
  
  plot.listR <- list(experiment = NULL, antibody = NULL)
  
  # Split data by experiment (for 1st tab)
  plot.listR$experiment <- data %>% 
    split(.$experiment) %>% 
    map( ~ mainPlot(data = ., plotTitle = paste("Experiment:", .$experiment), ...))%>% 
    keep(~ nrow(.$data) > 0 ) 
  
  # If antibodies split by experiment or not
  if(byExperiment){
    
    plot.listR$antibody <- data %>% 
      split(list(.$experiment, .$antibody_id)) %>% 
      map( ~ mainPlot(data = ., plotTitle = paste("Experiment:", .$experiment), ...)) %>% 
      keep(~ nrow(.$data) > 0 )
    
  } else {
    
    plot.listR$antibody <- data %>% 
      split(.$antibody_id) %>% 
      map( ~ mainPlot(data = ., plotTitle = paste("Experiment:", .$experiment), ...)) %>% 
      keep(~ nrow(.$data) > 0 )  # Remove plots that contain no data

  }
  
 # Return the list containing experiment and antibody plots
  plot.listR
}