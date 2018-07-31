library(pool)
library(DBI)
library(tools)

# Links:
# https://stackoverflow.com/questions/24265980/reset-inputs-button-in-shiny-app#24269691
# 192.168.49.15
getPgConnection <- function(userName, password) {
  pool <- dbPool(
    drv = RPostgreSQL::PostgreSQL(),
    dbname = "tusk_antibodies",
    host = "localhost",
    user = userName,
    port = 5432,
    password = password
  )
  pgConn <-  poolCheckout(pool)
  
  return(pgConn)
  
}


# Pull Data

pullAntibodiesInformationAndSequence <- function(pgConn) {
  sql <- "SELECT * FROM ab_data.vw_antibodies_information_and_sequence"
  antibodiesInformationAndSequence <- dbFetch(dbSendQuery(pgConn, sql))
  return(antibodiesInformationAndSequence)
}



getAllDataForGivenAbName <- function(pgConn, abName) {
  #user_defined_crud_functions.get_all_data_for_given_ab_name(p_given_name TEXT)
  sqlTmpl <- "SELECT *  FROM user_defined_functions.get_all_data_for_given_ab_name(?abName)"
  sql <- sqlInterpolate(DBI::ANSI(), sqlTmpl, abName = abName)
  allDataForGivenAbName <- dbFetch(dbSendQuery(pgConn, sql))
  
  return(allDataForGivenAbName)
  
}


getAllDataForAASeq <- function(pgConn, abSeqAA) {
  sqlTmpl <- "SELECT * FROM user_defined_functions.get_all_data_for_aa_seq(?abSeqAA)"
  sql <- sqlInterpolate(DBI::ANSI(), sqlTmpl, abSeqAA = abSeqAA)
  allDataForAASeq <- dbFetch(dbSendQuery(pgConn, sql))
  
  return(allDataForAASeq)
  
}

getMatchedSequencesForSubseq <- function(pgConn, subSeq) {
  sqlTmpl <- "SELECT * FROM user_defined_functions.get_matched_sequences_for_subseq(?subSeq)"
  sql <- sqlInterpolate(DBI::ANSI(), sqlTmpl, subSeq = subSeq)
  matchedSequencesForSubseq <- dbFetch(dbSendQuery(pgConn, sql))
  
  return(matchedSequencesForSubseq)
  
}