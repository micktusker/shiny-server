library(pool)
library(DBI)


## enable bookmarking ##
# enableBookmarking(store = "url")

#http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html
#psql -U micktusker -h 127.0.0.1 postgres
pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = "",
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


# Return all column names for a given experiment
get.datatype.column.names.for.experiment <- function(experiment.name) {
  tmpl <- "SELECT datatype_column_name FROM shiny_stored_procs.get_datatype_column_names_for_experiment('%s')"
  sql <- sprintf(tmpl, experiment.name)
  column.names.for.experiment <- as.vector(dbGetQuery(pg.conn, sql))
}

get.experiment.assay.datatype.dataframe <- function() {
  sql <- "SELECT experiment_name, assay_type, datatype_name FROM shiny_stored_procs.get_experiment_assay_datatype_dataframe()"
  experiment.assay.datatype.dataframe <- dbGetQuery(pg.conn, sql)
}
#experiment.assay.datatype.dataframe <- get.experiment.assay.datatype.dataframe()

# Call a stored procedure to get a Pan T Cell Data for a specified datatype.name.
get.pan.tcell.data <- function(experiment.name, datatype.name) {

  tmpl <-  "SELECT * FROM shiny_stored_procs.get_data_for_experiment_datatype('%s', '%s')"
  
  experimentList <- data.frame()
  
  for(i in seq_along(experiment.name)){
      sql <- sprintf(tmpl, experiment.name[i], datatype.name)
      df <- dbGetQuery(pg.conn, sql) %>% 
        mutate(experiment = experiment.name[i])
      experimentList <-  rbind(experimentList, df)
     
  }
  experimentList$antibody_id <- trimws(experimentList$antibody_id)

  return(experimentList)
}
