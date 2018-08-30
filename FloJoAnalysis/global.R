library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)

# Sub-directory where the RDS files are stored (relative to the Shiny App directory)
RDS_FILE_SUBDIR <- './uploaded_files'

# Return a vector of RDS file names in the ROOT_DIR.
# Used to populate UI file name "selectInput" created in "server.R".
getRdsFiles <- function() {
  rdsFileNames <- list.files(path = RDS_FILE_SUBDIR, pattern = '*rds$')
  return(rdsFileNames)
}


getFullTable <- function(rdsFiles) {
  #Load files
  rdsFiles <- getRdsFiles()
  fileList <- file.path(RDS_FILE_SUBDIR, rdsFiles)
  dat_list = lapply(fileList, function (x) data.table(readRDS(x)))
  fullTable = rbindlist(dat_list, fill = TRUE)
  
  #remove expression that causes trouble -> âˆ’
  fullTable <- as.data.frame(lapply(fullTable, function(x) {
    gsub("âˆ’", "_", x)}), stringsAsFactors = FALSE)
  
  #Make additional columns numeric
  numericColumns <- names(fullTable)[!names(fullTable) %in%  c("name", "Path", "Population", "Parent", "Donor", "sample", "donorList", "panelList", "stainList")]
  for(numericColumn in numericColumns) {
    fullTable[[numericColumn]] <- as.numeric(fullTable[[numericColumn]])
  }
  
  #Add extra statistic
  fullTable <- mutate(fullTable,frequency_of_Parent = (Count/ParentCount)*100)
  
  return(fullTable)
}

getPanelNames <- function(fullTable) {
  panelNames <- unique(fullTable$panelList)
  
  return(as.vector(panelNames))
  
}

getPopulationNames <- function(fullTable) {
  populationNames <- unique(fullTable$Population)
  
  return(as.vector(populationNames))
  
}

getVariableNames <- function(plotSet) {
  variableNames <- sort(colnames(dplyr::select_if(plotSet, is.numeric)))
  
  return(as.vector(variableNames))
  
}

getTableList <- function(fullTable, populations) {
  # Subset fulltable and subtract FMOs --------------------------------------------------------
  ##Get subset of data
  plotSet <- subset(fullTable, Population %in% populations)
  plotSet <- mutate(plotSet,ID = paste(donorList, Population, sep = '_'))
  plotSet <- mutate(plotSet, Indication = strsplit(ID,'_')[[1]][1])
  
  
  ##subtract FMOs
  FMOSubtractSet <- plotSet[c("ID","name","Path","Population","Parent","Count","ParentCount", "donorList", "panelList", "stainList", "frequency_of_Parent", "gMFI_Comp.PE.A")]
  FMOSubtractSet <- subset(FMOSubtractSet, stainList == "Full stain"|stainList == "CD25 FMO")
  FMOSubtractSet <- reshape(FMOSubtractSet, idvar = "ID", timevar = "stainList", direction = "wide")
  
  pathSplits <- data.frame(do.call('rbind', strsplit(as.character(FMOSubtractSet$'Path.Full stain'),'/',fixed=TRUE)))
  for(i in 1:ncol(pathSplits)){
    if(length(unique(pathSplits[,i]))>1){
      #create the extra column in FMOSubtractSet that has the right FMO value to subtract etc
      FMOSubtractSet$bello <- pathSplits[,i]
      dfFMO <- merge(data.frame(FMOSubtractSet$ID, FMOSubtractSet$`Population.Full stain`,FMOSubtractSet$`gMFI_Comp.PE.A.CD25 FMO`),data.frame(unique(pathSplits[,i])), by.x = "FMOSubtractSet..Population.Full.stain.", by.y = "unique.pathSplits...i..")
      FMOSubtractSet$bello <- paste0(FMOSubtractSet$`donorList.Full stain`,"_",FMOSubtractSet$bello) 
      FMOSubtractSet <- merge(dfFMO, FMOSubtractSet, by.x = "FMOSubtractSet.ID", by.y = "bello")
      FMOSubtractSet <- mutate(FMOSubtractSet, Adjusted_CD25_PE_gMFI = ifelse(`gMFI_Comp.PE.A.Full stain` - `FMOSubtractSet..gMFI_Comp.PE.A.CD25.FMO.`>0,`gMFI_Comp.PE.A.Full stain` - `FMOSubtractSet..gMFI_Comp.PE.A.CD25.FMO.`,0))
      plotSet <- subset(plotSet, stainList == "Full stain")
      plotSet <- merge(plotSet,data.frame(FMOSubtractSet$ID,FMOSubtractSet$Adjusted_CD25_PE_gMFI),by.x = "ID",by.y = "FMOSubtractSet.ID")
      break
    }
  }
  
  #plotSet <- subset(plotSet, Population == "B cells" | Population == "Myeloid DC" | Population == "Plasmacytoid DC" | Population == "Lin-" | Population == "CD56 high" | Population == "CD56 low" | Population == "Classical Monocytes" | Population == "Intermediate Monocytes" | Population == "Non-classical monocytes" | Population == "T cells") ##ASSIGN INPUT FROM GUI
  
  ##Dataframe per donor and dynamically figure out x-axis labels
  tableList <- list()
  for (i in 1:length(unique(FMOSubtractSet$`donorList.Full stain`))){
    plotTableName <- unique(FMOSubtractSet$`donorList.Full stain`)[i]
    tableListItem <- subset(plotSet, donorList == unique(FMOSubtractSet$`donorList.Full stain`)[i])
    change <- tableListItem[duplicated(tableListItem$Parent),]$Parent
    tableListItem <- within(tableListItem, { xLabels = ifelse(Parent %in% change, Parent, Population) })
    tableList[[plotTableName]] <- tableListItem
  }
  
  return(tableList)
  
}

