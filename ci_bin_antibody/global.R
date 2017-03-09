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