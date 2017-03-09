library(readxl)
library(pool)
library(DBI)

# http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html

pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = "analyses",
  host = "localhost",
  user = "michaelmaguire",
  port = 5432
)

pg.conn <- poolCheckout(pool)

dir.for.uploaded.files <- './uploaded_files'
if(!dir.exists(dir.for.uploaded.files)) {
  dir.create(dir.for.uploaded.files)
}

store.file <- function(from.fullpath, from.basename) {
  if(file.exists(file.path(dir.for.uploaded.files, from.basename))) {
    file.remove(file.path(dir.for.uploaded.files, from.basename))
  }
  file.copy(from.fullpath, file.path(dir.for.uploaded.files, from.basename))
  return(file.path(dir.for.uploaded.files, from.basename))
}

get.sheet.names <- function(full.path) {
  return(excel_sheets(full.path))
}

load.sheet.to.postgres <- function(xl.filename, sheet.name) {
  sheet.as.df <- as.data.frame(read_excel(xl.filename, sheet.name))
  dbWriteTable(pg.conn, sheet.name, sheet.as.df, row.names=FALSE)
  inserted.row.count <- dbExecute(pg.conn, 'SELECT insert_row_count FROM transfer_cord_experiments()')
  return(inserted.row.count)
}
