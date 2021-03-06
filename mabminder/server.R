shinyServer(function(input, output, session){
  db <- reactiveValues(pgConn = NULL, abSummaryDF = NULL, filenamesStoredOnServer = NULL, abCommonIdentifiers = NULL)
  observeEvent(input$btn_login, {
    userName <- input$user_name
    password <- input$password
    db$pgConn <- getPgConnection(userName, password)
    db$abSummaryDF <- pullAntibodiesInformationAndSequence(db$pgConn)
    db$filenamesStoredOnServer <- getFilenamesStoredOnServer(db$pgConn)
    db$abCommonIdentifiers <- unique(sort(c("", db$abSummaryDF$common_identifier)))
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
  # Upload/Download files
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
  
  # Add Ab note
  output$ab_list_add_note_to_ab <- renderUI({
    selectInput("ab_list_add_note_to_ab", label = "Select Antibody for Note", choices = db$abCommonIdentifiers)
  })
  observeEvent(input$btn_add_ab_note, {
    abCommonIdentifier <- input$ab_list_add_note_to_ab
    abNoteText <- input$txt_ab_note_text
    loadResult <- loadAbNote(db$pgConn, abCommonIdentifier, abNoteText)
    output$txto_loaded_ab_note_result <- renderText(loadResult)
  })
  
  # Searching
  observeEvent(input$btn_ab_name_search_db, {
    abName <- input$txt_ab_name_search_db
    allDataForGivenAbName <- getAllDataForGivenAbName(db$pgConn, abName)
    output$dt_ab_name_search_db <- DT::renderDataTable(allDataForGivenAbName) 
  })
  
  observeEvent(input$btn_ab_seq_search_db, {
    abSeqAA <- input$txta_ab_seq_search_db
    allDataForAASeq <- getAllDataForAASeq(db$pgConn, abSeqAA)
    output$dt_ab_seq_search_db <- DT::renderDataTable(allDataForAASeq)
  })
  
  observeEvent(input$btn_ab_seq_search_subseq_db, {
    subSeq <- input$txta_ab_seq_search_subseq_db
    matchedSequencesForSubseq <- getMatchedSequencesForSubseq(db$pgConn, subSeq)
    output$dt_ab_seq_search_subseq_db <- DT::renderDataTable(matchedSequencesForSubseq)
  })
})