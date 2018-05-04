dirForUploadedFiles <- './uploaded_files'
if(!dir.exists(dirForUploadedFiles)) {
  dir.create(dirForUploadedFiles)
}

storeFile <- function(fromFullPath, fromBasename) {
  if(file.exists(file.path(dirForUploadedFiles, fromBasename))) {
    file.remove(file.path(dirForUploadedFiles, fromBasename))
  }
  file.copy(fromFullPath, file.path(dirForUploadedFiles, fromBasename))
  return(file.path(dirForUploadedFiles, fromBasename))
}