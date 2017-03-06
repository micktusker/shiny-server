library(pool)
library(DBI)

# http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html

pool <- dbPool(
  drv = RSQLite::SQLite(),
  dbname = "crud_demo.db"
)

conn <- poolCheckout(pool)
insert.row <- function(name, favourite_pkg, used_shiny, r_num_years, os_type) {
  dbBegin(conn)
  sql <- 'INSERT INTO mytable(name, favourite_pkg, used_shiny, r_num_years, os_type) VALUES(:name, :favourite_pkg, :used_shiny, :r_num_years, :os_type)'
  stmt <- dbSendQuery(conn, sql)
  dbBind(stmt, params = list(name = name, favourite_pkg = favourite_pkg, used_shiny = used_shiny, r_num_years = r_num_years, os_type = os_type))
  results.affected <- dbGetRowsAffected(stmt)
  dbClearResult(stmt)
  dbCommit(conn)
  return(results.affected)
}
