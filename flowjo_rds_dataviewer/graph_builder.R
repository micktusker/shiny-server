#open libraries
library(flowWorkspace)
library(plyr)
library(dplyr)
library(ggplot2)
#library(ggthemes)
#library(extrafont)
library(scales)
#library(hmisc)
library(cytofkit)
library(scales)
library(wesanderson)
library(RColorBrewer)

#Functions!!
squish_trans <- function(from, to, factor) {
  
  trans <- function(x) {
    
    # get indices for the relevant regions
    isq <- x > from & x < to
    ito <- x >= to
    
    # apply transformation
    x[isq] <- from + (x[isq] - from)/factor
    x[ito] <- from + (to - from)/factor + (x[ito] - to)
    
    return(x)
  }
  
  inv <- function(x) {
    
    # get indices for the relevant regions
    isq <- x > from & x < from + (to - from)/factor
    ito <- x >= from + (to - from)/factor
    
    # apply transformation
    x[isq] <- from + (x[isq] - from) * factor
    x[ito] <- to + (x[ito] - (from + (to - from)/factor))
    
    return(x)
  }
  
  # return the transformation
  return(trans_new("squished", trans, inv))
}

setwd("H:/Programming/R/FlowLink/TSK04_Trans_002/") ##ASSIGN INPUT FROM GUI

#Load donors
donorsList <- c("workspace002_donor1.rds","workspace002_donor2.rds","workspace002_donor3.rds") ##ASSIGN INPUT FROM GUI
donors.data<-list()
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

#Making a simple Bar graph-----------------------------------------------------------------
##Get subset of data
plotSet <- subset(fullTable, Population == "aTreg cells (Fr. II)/CD25+") ##ASSIGN INPUT FROM GUI
plotSet <- subset(plotSet, sample == "full_stain" | sample =="CD25_FMO") ##ASSIGN INPUT FROM GUI

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
print(plot1)



#Making a stacked columns graph---------------------------------------------------------------
##Get subset of data
#plotSet <- subset(fullTable, Population == "CD4+" | Population == "aTreg cells (Fr. II)" | Population == "CD45RA_FoxP3lo non-Treg cell fraction (Fr. III)" | Population == "rTreg" | Population == "CD8+" |  Population == "CD8+/CD25+") ##ASSIGN INPUT FROM GUI
plotSet <- subset(plotSet, sample == "full_stain") ##ASSIGN INPUT FROM GUI
plotSet <- subset(plotSet, Donor == "5") ##ASSIGN INPUT FROM GUI

##summary table
statSet <- ddply(plotSet, c("Population"), summarise,
                 N    = length(frequency_of_Parent),
                 mean = mean(frequency_of_Parent),
                 sd   = sd(frequency_of_Parent),
                 se   = sd / sqrt(N),
                 frequency_of_Parent = mean
)

##plot the bar graph - 'scale_x_discrete(labels=' needs generalising, probably with GUI input
plot2 <- ggplot(plotSet, aes(x=Parent, y=Count, fill=Population)) + geom_bar(stat="identity") + theme_classic() + labs(title="TIL Composition") + theme(plot.title = element_text(hjust = 0.5), axis.title.x=element_blank()) + scale_x_discrete(labels=c("B cells", "Lin-", "Dendritic cells", "T cells", "Monocytes", "NK cells"))+scale_fill_brewer(palette="Set3")#+scale_fill_hue(l=100, c=100)#+scale_y_continuous(trans = squish_trans(10000, 40000, 10), breaks = c(0, 2000, 4000, 6000, 8000, 10000, 20000,30000))
print(plot2)


#Fancy FACS plots - these don't work from the RDS files, only the GatingSets
#for more see http://bioconductor.org/packages/release/bioc/vignettes/flowWorkspace/inst/doc/plotGate.html
plotGate(gs_full, "aTreg cells (Fr. II)", xbin = 0, main = "Graph title")

#t-SNE
## install
##source("https://bioconductor.org/biocLite.R")
##biocLite("cytofkit")

## run new analysis
cytofkit_GUI()

## open old analysis (or recently finished analysis)
cytofkitShinyAPP()
