library(pool)
library(DBI)



# http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html
# psql -U micktusker -h 127.0.0.1 postgres
pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = "facs_analysis_test",
  host = "192.168.49.15",
  user = "micktusker",
  port = 5432,
  password = "Ritalin0112!"
)

pg.conn <- poolCheckout(pool)

# Provides a list available experiments to the UI
get.experiments <- function(){
  sql <- "SELECT DISTINCT experiment_name FROM stored_data.loaded_files_metadata"
  experiments <- as.vector(dbGetQuery(pg.conn, sql))
}

# Provides a list of available data types to the UI.
get.data.columns <- function(){
  sql <- "SELECT data_column_name FROM stored_data.vw_pan_tcell_facs_data_columns"
  data.columns <- as.vector(dbGetQuery(pg.conn, sql))
}
# Call a stored procedure to get a Pan T Cell Data for a specified datatype.name.
get.pan.tcell.data <- function(experiment.name, datatype.name) {
  tmpl <-  "SELECT
              uploaded_excel_file_basename donor_day,
              sample_identifier,
              antibody_id,
              antibody_concentration,
              replicates, replicates_avg 
            FROM
              get_single_datatype('%s', '%s')
            ORDER BY 
              antibody_id,
              antibody_concentration"
  sql <- sprintf(tmpl, experiment.name, datatype.name)
  df <- dbGetQuery(pg.conn, sql)
}


