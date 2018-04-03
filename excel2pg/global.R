library(readxl)
library(pool)
library(DBI)

# http://cran.fhcrc.org/web/packages/RSQLite/vignettes/RSQLite.html

pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = "facs_analysis_test",
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

write.sheet.as.tsv <- function(full.path, sheet.name, skip.rowcount = 0) {
  print(full.path)
  df <- readxl::read_xlsx(full.path, sheet.name, skip = skip.rowcount, col_types = "text", col_names = FALSE)
  write.table(df, file = paste0(sheet.name, '.tsv'), 
              append = FALSE, sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE, na = "")
}

load.data.to.pg <- function(tsv.file.name) {
  tmpl <- "SELECT load_transit_tmp('%s')"
  conn <- file(tsv.file.name, 'r')
  lines <- readLines(conn)
  for(i in 1:length(lines)) {
    sql <- sprintf(tmpl, lines[i])
    result <- dbGetQuery(pg.conn, sql)
  }
  close(conn)
}

add.full.excel.path.to.metadata <- function(full.excel.path) {
  line.to.append <- paste0(paste('Uploaded Excel File Name', full.excel.path, sep = "\t"), "\n")
  cat(line.to.append, file = 'FileMetaData.tsv', append = TRUE)
}


transfer.data.to.tables <- function() {
  sql = "SELECT load_facs_data_tables()"
  dbGetQuery(pg.conn, sql)
}

get.column.names <- function(data.file.name) {
  conn <- file(data.file.name, 'r')
  lines <- readLines(conn)
  close(conn)
  column.name.line <- lines[1]
  file.column.names <- data.frame(unlist(strsplit(column.name.line, '\t')))
  names(file.column.names) <- c('column_name')
  return(file.column.names)
}
