shinyServer(function(input, output) {
  observeEvent(input$btn_align_run, {
    fastaSequences <- input$sequences_to_align
    alignedSequences <- getNamedGapAlignedSequences(fastaSequences)
    generatedHtml <- generateHtmlOutput(alignedSequences)
    output$aa_alignment <- renderUI(HTML(generatedHtml))
    sequenceIds <- sort(names(alignedSequences))
    output$sequence_ids <- renderUI(
      selectInput("sequence_id", "Choose Comparator", choices = sequenceIds)
    )
  })
  observeEvent(input$btn_align_difference_run, {
    comparatorName <- input$sequence_ids
    
  })
})