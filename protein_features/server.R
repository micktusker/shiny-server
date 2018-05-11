server <- function(input, output) {
  observeEvent(input$btn_run, {
    aa_seq <- input$aa_seq
    proteinResultsTables <- getProteinResultsTables(aa_seq)
    paramValues <- proteinResultsTables[[1]]
    aaCounts <- proteinResultsTables[[2]]
    output$param_values <- renderTable(paramValues)
    output$aa_counts <- renderTable(aaCounts)
  })
}