library(pool)
library(DBI)
library(tools)

# Links:
# https://stackoverflow.com/questions/24265980/reset-inputs-button-in-shiny-app#24269691
# 192.168.49.15
# Note: This is using the package RPostgres and NOT RPostgreSQL!!
getPgConnection <- function(userName, password) {
  pool <- dbPool(
    drv = RPostgres::Postgres(),
    dbname = "mabminder",
    host = "localhost",
    user = userName,
    port = 5432,
    password = password
  )
  pgConn <-  poolCheckout(pool)
  
  return(pgConn)
  
}

createNewAntibodySequenceEntry <- function(pgConn, commonIdentifier, antibodyType, geneName, antibodySource, sourceDatabaseUrl, chainSequence, chainType) {
  sqlTmpl <- 'SELECT create_new_antibody_sequence_entry FROM user_defined_crud_functions.create_new_antibody_sequence_entry(?commonIdentifier, ?antibodyType, ?geneName, ?antibodySource, ?sourceDatabaseUrl, ?chainSequence, ?chainType)'
  sql <- sqlInterpolate(DBI::ANSI(), sqlTmpl, commonIdentifier = commonIdentifier, 
                        antibodyType = antibodyType, 
                        geneName = geneName, 
                        antibodySource = antibodySource, 
                        sourceDatabaseUrl = sourceDatabaseUrl, 
                        chainSequence = chainSequence, 
                        chainType = chainType)
  loadResult <- DBI::dbGetQuery(pgConn, sql)
  
  return(loadResult)
  
}

# Pull Data

pullAntibodiesInformationAndSequence <- function(pgConn) {
  sql <- "SELECT * FROM ab_data.vw_antibodies_information_and_sequence"
  antibodiesInformationAndSequence <- dbFetch(dbSendQuery(pgConn, sql))
  return(antibodiesInformationAndSequence)
}


# Upload a file
dirForUploadedFiles <- './uploaded_files'
if(!dir.exists(dirForUploadedFiles)) {
  dir.create(dirForUploadedFiles)
}

makeFullDir <- function(targetIdentifier, antibodyName) {
  if(!dir.exists(file.path(dirForUploadedFiles, targetIdentifier))) {
    dir.create(file.path(dirForUploadedFiles, targetIdentifier))
  }
  if(!dir.exists(file.path(dirForUploadedFiles, targetIdentifier, antibodyName))) {
    dir.create(file.path(dirForUploadedFiles, targetIdentifier, antibodyName))
  }
  
  return(file.path(dirForUploadedFiles, targetIdentifier, antibodyName))
  
}

writeFileRecordToDB <- function(pgConn, antibodyName, fileChecksum, documentName, documentDescription) {
  sqlTmpl <- "SELECT user_defined_crud_functions.load_antibody_document(?antibodyName, ?fileChecksum, ?documentName, ?documentDescription)"
  sql <- sqlInterpolate(DBI::ANSI(), sqlTmpl,
                        antibodyName = antibodyName,
                        fileChecksum = fileChecksum,
                        documentName = documentName,
                        documentDescription = documentDescription)
  loadResult <- DBI::dbGetQuery(pgConn, sql)

  return(loadResult$load_antibody_document)
  
}

#loadResult <- storeFile(db$pgConn, inputFileName, fromBasename, documentDescription, targetIdentifier, antibodyName)
storeFile <- function(pgConn, fromFullPath, fromBasename, documentDescription, targetIdentifier, antibodyName) {
  fullDir <- makeFullDir(targetIdentifier, antibodyName)
  newFileName <- file.path(fullDir, fromBasename)
  file.copy(fromFullPath, newFileName)
  chkSum <- md5sum(file.path(newFileName))
  loadResult <- as.vector(writeFileRecordToDB(pgConn, antibodyName, chkSum, newFileName, documentDescription))
  
  return(loadResult)
  
}

# Download files
getFilenamesStoredOnServer <- function(pgConn) {
  sql <- 'SELECT user_defined_crud_functions.get_uploaded_filenames()'
  filenamesStoredOnServer <- DBI::dbGetQuery(pgConn, sql)
  
  return(filenamesStoredOnServer)
  
}

# Add note to antibody
loadAbNote <- function(pgConn, abCommonIdentifier, abNoteText) {
  sqlTmpl <- "SELECT add_note_to_antibody FROM user_defined_crud_functions.add_note_to_antibody(?abCommonIdentifier, ?abNoteText)"
  sql <- sqlInterpolate(DBI::ANSI(), sqlTmpl,
                        abCommonIdentifier = abCommonIdentifier, 
                        abNoteText = abNoteText)
  loadResult <- DBI::dbGetQuery(pgConn, sql)
  
  return(loadResult$add_note_to_antibody)
  
}