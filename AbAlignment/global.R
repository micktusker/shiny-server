library(msa)
library(seqinr)
library(stringr)
library(seqRFLP)

# Temporary files for transferring sequences from one format to another or from one R package to another.
tmpFastaFileName <- 'tmp.fsa'
tmpTsvFileName <- 'tmp.tsv'

# Run the ClustalOmega alignment and reurned the aligned sequences with the sequence identifiers as names.
getNamedGapAlignedSequences <- function(inputSequences, isFasta = FALSE) {
  if(substr(inputSequences, 1, 1) == '>') {
    isFasta <- TRUE
  }
  if(isFasta) {
    fileConn <- file(tmpFastaFileName)
    writeLines(inputSequences, fileConn)
    close(fileConn)
  } else {
    createFastaFromTsvFile(inputSequences)
  }
  stringSet <- readAAStringSet(tmpFastaFileName)
  alnSet <- msa(stringSet, "ClustalOmega")
  seqinrAlnSet <- msaConvert(alnSet, type="seqinr::alignment")
  unlink(tmpFastaFileName)
  namedGapAlignedSequences <- seqinrAlnSet$seq
  names(namedGapAlignedSequences) <- seqinrAlnSet$nam
  
  return(namedGapAlignedSequences)
  
}

# Use the R package "seqRFLP" to convert tab-delimited sequence input into FASTA format that is written to a FASTA file.
createFastaFromTsvFile <- function(tsvSequences) {
  fileConn <- file(tmpTsvFileName)
  writeLines(tsvSequences, fileConn)
  close(fileConn)
  df <- read.table(tmpTsvFileName, sep = "\t", stringsAsFactors = FALSE)
  dataframe2fas(df, file = tmpFastaFileName)
  unlink(tmpTsvFileName)
  
  return(TRUE)
  
}

# Taking two gap-aligned sequences as inputs, return a string where a period (".") represents positions
#  where the two amino acids are the same and the amino acid letter is used where the positions differ.
getDifferencesBetweenTwoGapAllignedSequences <- function(comparatorSequence, compareToSequence) {
  comparison <- vector(mode = "character", length = length(comparatorSequence))
  for(i in 1:nchar(comparatorSequence)) {
    comparatorAA <- substr(comparatorSequence, i, i)
    compareToAA <- substr(compareToSequence, i, i)
    if(comparatorAA == compareToAA) {
      comparison[i] <- '.'
    } else {
      comparison[i] <- compareToAA
    }
  }
  
  return(paste(comparison, collapse = ''))
  
}

# Get the amino acid differences for a vector of sequences.
getDifferencesBetweenTwoGapAllignedSequencesAll <- function(comparatorSequence, compareToSequences) {
  comparedSequences <- vector(mode = "character", length = length(compareToSequences))
  for(i in 1:length(compareToSequences)) {
    comparedSequences[i] <- getDifferencesBetweenTwoGapAllignedSequences(comparatorSequence, compareToSequences[i])
  }
  
  return(comparedSequences)
  
}

# Get a single sequence from a named vector using the given name.
getSequenceForName <- function(sequenceName, namedGapAlignedSequences) {
  
  return(namedGapAlignedSequences[sequenceName])
  
}

# Remove a sequence with the given name from a named vector
removeNamedSequence <- function(sequenceName, namedGapAlignedSequences) {
  indexesToRemove <- which(namedGapAlignedSequences == namedGapAlignedSequences[sequenceName])
  namedGapAlignedSequencesMinusNamedSequence <- namedGapAlignedSequences[-indexesToRemove]
  
  return(namedGapAlignedSequencesMinusNamedSequence)
  
}

# Create HTML output to display a gapped alignment.
generateHtmlOutput <- function(namedGapAlignedSequences) {
  namesPrependedGapAlignedSequences <- paste(names(namedGapAlignedSequences), namedGapAlignedSequences, sep = ":\t")
  generatedHtmlOutput <- paste0('<pre>', paste(namesPrependedGapAlignedSequences, collapse = '<br />'), '</pre>')
  
  return(generatedHtmlOutput)
  
}