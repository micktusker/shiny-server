library(pool)
library(DBI)



# http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html
# psql -U micktusker -h 127.0.0.1 postgres
pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = "facs_analysis",
  host = "127.0.0.1",
  user = "micktusker",
  port = 5432,
  password = ""
)

pg.conn <- poolCheckout(pool)

# Call a stored procedure to get a Pan T Cell Data for a specified datatype.name.
get.pan.tcell.data <- function(datatype.name, experiment.name, source.file.description) {
  tmpl <-  "SELECT sample_identifier, replicates, replicates_avg 
           FROM get_single_datatype('%s', '%s', '%s')
           WHERE sample_identifier IS NOT NULL"
  sql <- sprintf(tmpl, datatype.name, experiment.name, source.file.description)
  df <- dbGetQuery(pg.conn, sql)
  return(df)
}
