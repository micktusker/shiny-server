library(pool)
library(DBI)



# http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html
# psql -U micktusker -h 127.0.0.1 postgres
pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = "facs_analysis_test",
  host = "localhost",
  user = "micktusker",
  port = 5432,
  password = ""
)

pg.conn <- poolCheckout(pool)

# Call a stored procedure to get a Pan T Cell Data for a specified datatype.name.
get.pan.tcell.data <- function(datatype.name, experiment.name) {
  tmpl <-  "SELECT
              uploaded_excel_file_basename donor_day,
              sample_identifier,
              antibody_id,
              antibody_concentration,
              replicates, replicates_avg 
            FROM
              get_single_datatype('%s', '%s')"
  sql <- sprintf(tmpl, experiment.name, datatype.name)
  df <- dbGetQuery(pg.conn, sql)
  return(df)
}
