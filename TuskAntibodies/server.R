userName <- "michael.maguire@tusktherapeutics.com"
password <- "Meitheamh!12"
pgConn <- getPgConnection(userName, password)

shinyServer(function(input, output, session){
  db <- reactiveValues(abSummaryDF = NULL, filenamesStoredOnServer = NULL, abCommonIdentifiers = NULL)
  observeEvent(input$btn_pulldata, {
#    userName <- "michael.maguire@tusktherapeutics.com"
#    password <- "Meitheamh!12"
#    db$pgConn <- getPgConnection(userName, password)
    db$abSummaryDF <- pullAntibodiesInformationAndSequence(pgConn)
    output$antibody_data_summary <- DT::renderDataTable({db$abSummaryDF})
  })
  # Searching
  observeEvent(input$btn_ab_name_search_db, {
    abName <- input$txt_ab_name_search_db
    allDataForGivenAbName <- getAllDataForGivenAbName(pgConn, abName)
    output$dt_ab_name_search_db <- DT::renderDataTable(allDataForGivenAbName) 
  })
  
  observeEvent(input$btn_ab_seq_search_db, {
    abSeqAA <- input$txta_ab_seq_search_db
    allDataForAASeq <- getAllDataForAASeq(pgConn, abSeqAA)
    output$dt_ab_seq_search_db <- DT::renderDataTable(allDataForAASeq)
  })
  
  observeEvent(input$btn_ab_seq_search_subseq_db, {
    subSeq <- input$txta_ab_seq_search_subseq_db
    matchedSequencesForSubseq <- getMatchedSequencesForSubseq(pgConn, subSeq)
    output$dt_ab_seq_search_subseq_db <- DT::renderDataTable(matchedSequencesForSubseq)
  })
})