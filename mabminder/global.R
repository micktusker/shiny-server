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

# Upload a file
dirForUploadedFiles <- './uploaded_files'
if(!dir.exists(dirForUploadedFiles)) {
  dir.create(dirForUploadedFiles)
}

writeFileRecordToDB <- function(pgConn, chkSum, fromBasename, documentDescription) {
  print("Called!")
}

storeFile <- function(pgConn, fromFullPath, fromBasename, documentDescription) {
  print(fromBasename)
  if(file.exists(file.path(dirForUploadedFiles, fromBasename))) {
    file.remove(file.path(dirForUploadedFiles, fromBasename))
  }
  file.copy(fromFullPath, file.path(dirForUploadedFiles, fromBasename))
  chkSum <- md5sum(file.path(dirForUploadedFiles, fromBasename))
  writeFileRecordToDB(pgConn, chkSum, fromBasename, documentDescription)
  
  return(file.path(dirForUploadedFiles, fromBasename))
  
}