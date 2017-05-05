library(pool)
library(tidyverse)

# 
get.replicates.as.numeric.vector <- function(replicates.as.str) {
  replicates.as.numeric.vector <- as.numeric(unlist(strsplit(replicates.as.str, '[ , ]+', perl = TRUE)))
  return(replicates.as.numeric.vector)
}

#
get.conf.ints.for.replicates <- function(replicates.as.str, list.index.to.return) {
  replicates.as.numeric.vector <- get.replicates.as.numeric.vector(replicates.as.str)
  if(length(replicates.as.numeric.vector) < 2) return(NA)
  result <- t.test(replicates.as.numeric.vector)
  conf.ints <- list(lower = result$conf.int[1], upper = result$conf.int[2])
  return(conf.ints[[list.index.to.return]])
}

#
get.lower.conf.int <- function(replicates.as.str) {
  return(get.conf.ints.for.replicates(replicates.as.str, 1))
}
#
get.upper.conf.int  <- function(replicates.as.str) {
  return(get.conf.ints.for.replicates(replicates.as.str, 2))
}

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

# Call a stored procedure to get a Pan T Cell Data for a specified datatype.name.
get.pan.tcell.data <- function(experiment.name, datatype.name) {
  tmpl <-  "
  SELECT
  uploaded_excel_file_basename donor_day,
  sample_identifier,
  get_cd3_concentration(sample_identifier) cd3_concentration,
  antibody_id,
  antibody_concentration,
  replicates,
  replicates_avg,
  get_array_std_err_mean(get_delimited_str_as_numeric_array(replicates)) std_err_mean,
  get_array_stddev(get_delimited_str_as_numeric_array(replicates)) stddev
  FROM
  get_single_datatype('TSK01_vitro_024', 'viable_cells')
  ORDER BY 
  antibody_id,
  antibody_concentration"
  sql <- sprintf(tmpl, experiment.name, datatype.name)
  df <- dbGetQuery(pg.conn, sql)
  df$antibody_id <- trimws(df$antibody_id)
  return(df)
}
datatype.name <- 'cd4_percent_proliferation'
experiment.name <- 'TSK01_vitro_025'
df <- get.pan.tcell.data(experiment.name, datatype.name)

df$lower_ci <- sapply(df$replicates, function(replicates.as.str) {return(get.conf.ints.for.replicates(replicates.as.str, 1))})
df$upper_ci <- sapply(df$replicates, function(replicates.as.str) {return(get.conf.ints.for.replicates(replicates.as.str, 2))})
