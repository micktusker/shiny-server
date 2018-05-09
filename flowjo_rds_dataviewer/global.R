library(dplyr)
library(plyr)
library(ggplot2)


# Sub-directory where the RDS files are stored (relative to the Siny App directory)
RDS_FILE_SUBDIR <- './uploaded_files'

# Return a vector of RDS file names in the ROOT_DIR.
# Used to populate UI file name "selectInput" created in "server.R".
getRdsFiles <- function() {
  rdsFileNames <- list.files(path = RDS_FILE_SUBDIR, pattern = '*rds$')
  return(rdsFileNames)
}

getFullTable <- function(rdsFiles) {
  donorsList <- file.path(RDS_FILE_SUBDIR, rdsFiles)
  donors.data <- list()
  for (i in 1:length(donorsList)){
    donors.data[[i]]<-readRDS(donorsList[i])
    donors.data[[i]]$full_stain$Donor <- i
    donors.data[[i]]$CD25_FMO$Donor <- i
    donors.data[[i]]$CD38_FMO$Donor <- i
  }
  #add donor and sample columns then produce one large table
  fullTable <- NULL
  for (i in 1:length(donorsList)){
    donors.data[[i]]<-readRDS(donorsList[i])
    for (j in 1:length(attr(donors.data[[1]],"names"))){
      donors.data[[i]][[j]]$Donor <- i
      donors.data[[i]][[j]]$sample <- attr(donors.data[[1]],"names")[j]
      fullTable <- rbind(fullTable,donors.data[[i]][[j]])
    }
  }
  
  #remove expression that causes trouble -> âˆ’
  fullTable <- as.data.frame(lapply(fullTable, function(x) {
    gsub("âˆ’", "_", x)}), stringsAsFactors = FALSE)
  fullTable$Count <- as.numeric(as.character(fullTable$Count))
  fullTable$ParentCount <- as.numeric(as.character(fullTable$ParentCount))
  
  #Add extra statistic
  fullTable <- mutate(fullTable,frequency_of_Parent = (Count/ParentCount)*100)
  return(fullTable)
}

getPopulationNames <- function(fullTable) {
  populationNames <- unique(fullTable$Population)
  return(as.vector(populationNames))
}

getSampleNames <- function(fullTable) {
  sampleNames <- unique(fullTable$sample)
  return(as.vector(sampleNames))
}

getPlotAndSummaryList <- function(fullTable, populationNames, sampleNames) {
  plotAndSummaryList <- list()
  #Making a simple Bar graph-----------------------------------------------------------------
  ##Get subset of data
  plotSet <- subset(fullTable, Population %in% populationNames) ##ASSIGN INPUT FROM GUI
  plotSet <- subset(plotSet, sample %in% sampleNames) ##ASSIGN INPUT FROM GUI
  
  ##Need a section here that lets you say percentage of which population - help!
  
  ##summary table
  statSet <- ddply(plotSet, c("sample"), summarise,
                   N    = length(frequency_of_Parent),
                   mean = mean(frequency_of_Parent),
                   sd   = sd(frequency_of_Parent),
                   se   = sd / sqrt(N),
                   frequency_of_Parent = mean
  )
  
  ##plot the bar graph
  plot1 <- ggplot(plotSet, aes(x=sample, y=frequency_of_Parent)) + geom_dotplot(binaxis='y', binwidth = 1, stackdir='center') + stat_summary(fun.data=mean_sdl, fun.args = list(mult=1), geom="errorbar", color="black", width=0.2) + stat_summary(fun.y=mean, geom="point", color="red") + geom_bar(data=statSet,stat="identity", color="black", alpha=0.2) + theme_classic()+labs(title="Proportion of aTreg that are CD25+")
  plotAndSummaryList[['plot']] <- plot1
  plotAndSummaryList[['summary_table']] <- statSet
  return(plotAndSummaryList)
}