server <- function(input, output) {
  observeEvent(input$btn_load, {
    abName <- input$ab_name
    abSeq <- input$ab_seq
    retval <- loadAntibodySequence(abName, abSeq)
    output$retval <- renderText(as.character(jsonlite::toJSON(retval)))
  })
}