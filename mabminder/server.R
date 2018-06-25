shinyServer(function(input, output, session){
  db <- reactiveValues(pgConn = NULL, abSummaryDF = NULL, filenamesStoredOnServer = NULL)
  observeEvent(input$btn_login, {
    userName <- input$user_name
    password <- input$password
    db$pgConn <- getPgConnection(userName, password)
    db$abSummaryDF <- pullAntibodiesInformationAndSequence(db$pgConn)
    db$filenamesStoredOnServer <- getFilenamesStoredOnServer(db$pgConn)
    output$antibody_data_summary <- DT::renderDataTable({db$abSummaryDF})
    output$logged_status <- renderText(sprintf("%s logged in!", userName))
    
  })
  observeEvent(input$btn_logout, {
    DBI::dbDisconnect(db$pgConn)
    db$pgConn <- NULL
    output$logged_status <- renderText("Logged out!")
  })
  observeEvent(input$btn_load_ab, {
    commonIdentifier <- input$antibody_identifier
    print(commonIdentifier)
    antibodyType <- input$antibody_type
    antibodySource <- input$antibody_source
    geneName <- input$gene_name
    sourceDatabaseUrl <- input$source_database_url
    hChainSequence <- stringr::str_trim(input$hchain_sequence)
    lChainSequence <- stringr::str_trim(input$lchain_sequence)
    resultH <- ""
    resultL <- ""
    if(nchar(hChainSequence) > 1) {
      resultH <- createNewAntibodySequenceEntry(db$pgConn, 
                                                commonIdentifier,
                                                antibodyType,
                                                geneName,
                                                antibodySource,
                                                sourceDatabaseUrl,
                                                hChainSequence,
                                                'H')
    }
    if(nchar(lChainSequence) > 1) {
      resultL <- createNewAntibodySequenceEntry(db$pgConn, 
                                                commonIdentifier,
                                                antibodyType,
                                                geneName,
                                                antibodySource,
                                                sourceDatabaseUrl,
                                                lChainSequence,
                                                'L')
    }
    updateTextInput(session, "antibody_identifier", value = "")
    updateTextInput(session, "antibody_type", value = "")
    updateSelectInput(session, "antibody_source", selected = NULL)
    updateTextInput(session, "gene_name", value = "")
    updateTextInput(session, "source_database_url", value = "")
    updateTextInput(session, "hchain_sequence", value = "")
    updateTextInput(session, "lchain_sequence", value = "")
    output$retval <- renderText(stringr::str_c(resultH, resultL, sep = "\n"))
  })
  storedFilePath <- reactive({
    uploadFile <- input$file_upload
    if(is.null(uploadFile)) {
      return(NULL)      
    }
    inputFileName <- input$file_upload$datapath
    documentDescription <- input$document_description
    fromBasename <- input$file_upload$name
    targetIdentifier <- input$target_identifier_fileupload
    antibodyName <- input$antibody_name_fileupload
    loadResult <- storeFile(db$pgConn, inputFileName, fromBasename, documentDescription, targetIdentifier, antibodyName)
    
    return(loadResult)
    
  })
  
  output$file_uploaded <- renderText(storedFilePath())
  
  output$select_download_filename <- renderUI({
      selectInput("select_download_filename", label = "Select a file to download", choices = db$filenamesStoredOnServer, width="500px")
    })
  
  output$download_file <- downloadHandler(
    filename = function() {
      basename(input$select_download_filename)
    }, 
    content = function(file) {
      file.copy(input$select_download_filename, file)
    }, 
    contentType = NA)
})