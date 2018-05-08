#open libraries
library(flowWorkspace)
library("plyr")
library("dplyr")
library(ggplot2)
library(ggthemes)
library(extrafont)
library(scales)
library(hmisc)
library(cytofkit)

#Open a workspace
setwd("H:/Programming/R/FlowLink/TSK04_Trans_002/")
wsFile <- file.path("4-Data Analysis (Excel, Batch Report, Prism)/180228 RC3-5/Panel 2.wsp")
ws <- openWorkspace(wsFile)

#Parse full stain and FMO data for each donor into it's own RDS file
subsetList <- list()
for (j in 1:rapply(getSampleGroups(ws),function(x)length(unique(x)))[[1]]){ #what a convoluted way of getting the number 7!!
  subsetList <- list()
  for (i in 1:nrow(getFJWSubsetIndices(ws, key=NULL, value = NULL, j))){
    subsetNameInList <- paste0("gs_",i)
    subsetForList <- getPopStats(parseWorkspace(ws, name=j, path="2-Raw Data/180228 RC3-5/TSK04_trans_002 RC3-5 Panel 2/Stain Plate", subset=i))
    subsetList[[subsetNameInList]] <- subsetForList
  }
  if (j>=4 & j<=6){ #naming full stain and control data for each patient list - this will likely need user control as 4, 5 and 6 won't necessarily be the right groups
    attr(subsetList, "names")[1] <- "full_stain"
    attr(subsetList, "names")[2] <- "CD25_FMO"
    attr(subsetList, "names")[3] <- "CD38_FMO"
    filepath_RDS = paste0("workspace002_", "donor", j-3, ".rds") #might want to be more clever on donor naming
    saveRDS(assign(paste0("group",j),subsetList),file=filepath_RDS)
  }
  subset <- NULL
}

#gs_test <- parseWorkspace(ws, name=7, path="2-Raw Data/180228 RC3-5/TSK04_trans_002 RC3-5 Panel 2/Stain Plate", subset=1)
#plotGate(gs_test, "DCs and NK cells", xbin = 0, main = "Graph title")
#plotGate(parseWorkspace(ws, name=7, path="2-Raw Data/180228 RC3-5/TSK04_trans_002 RC3-5 Panel 2/Stain Plate", subset=1), "DCs and NK cells", xbin = 0, main = "Graph title")
