library(pool)
library(DBI)
library(jsonlite)

# Note: This is using the package RPostgres and NOT RPostgreSQL!!
pool <- dbPool(
  drv = RPostgres::Postgres(),
  dbname = "general",
  host = "192.168.49.15",
  user = "micktusker",
  port = 5432
)
pgConn <-  poolCheckout(pool)

loadAntibodySequence <- function(abName, abSeq, metaData = '{}') {
  sqlTmpl <- 'SELECT * FROM antibodies.add_new_antibody_sequence(?abName, ?abSeq, ?metaData)'
  sql <- sqlInterpolate(DBI::ANSI(), sqlTmpl, abName = abName, abSeq = abSeq, metaData = metaData)
  retval <- DBI::dbGetQuery(pgConn, sql)
  retval <- as.character(retval)
  return(jsonlite::fromJSON(retval))
}