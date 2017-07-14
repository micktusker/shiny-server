library(pool)
library(DBI)



# http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html
# psql -U micktusker -h 127.0.0.1 postgres
pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = "facs_analysis",
  host = "",
  user = "",
  port = 5432,
  password = ""
)

pg.conn <- poolCheckout(pool)

# Provides a list of available experiments to the UI
get.experiments <- function(){
  sql <- "SELECT experiment_name FROM shiny_stored_procs.get_experiment_names();"
  experiments <- as.vector(dbGetQuery(pg.conn, sql))
}

get.datatype.column.names <- function() {
  sql <- "SELECT datatype_column_name FROM shiny_stored_procs.get_datatype_column_names()"
  experiment.assay.datatype.dataframe <- dbGetQuery(pg.conn, sql)
}

get.experiment.assay.datatype.dataframe <- function() {
  sql <- "SELECT experiment_name, assay_type, datatype_name FROM shiny_stored_procs.get_experiment_assay_datatype_dataframe()"
  experiment.assay.datatype.dataframe <- dbGetQuery(pg.conn, sql)
}
experiment.assay.datatype.dataframe <- get.experiment.assay.datatype.dataframe()
# Call a stored procedure to get a Pan T Cell Data for a specified datatype.name.
get.pan.tcell.data <- function(experiment.name, datatype.name) {
  tmpl <-  "SELECT * FROM shiny_stored_procs.get_data_for_experiment_datatype('%s', '%s')"
  sql <- sprintf(tmpl, experiment.name, datatype.name)
  df <- dbGetQuery(pg.conn, sql)
  df$antibody_id <- trimws(df$antibody_id)
  return(df)
}
