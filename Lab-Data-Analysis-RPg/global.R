library(pool)
library(DBI)



# http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html
# psql -U micktusker -h 127.0.0.1 postgres
pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = "cd38",
  host = "127.0.0.1",
  user = "micktusker",
  port = 5432,
  password = ""
)

pg.conn <- poolCheckout(pool)
