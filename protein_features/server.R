server <- function(input, output) {
  observeEvent(input$btn_run, {
    aa_seq <- input$aa_seq
    proteinResultsTables <- getProteinResultsTables(aa_seq)
    paramValues <- proteinResultsTables[[1]]
    aaCounts <- proteinResultsTables[[2]]
    output$param_values_heading <- renderUI(HTML("<h2>Calculated parameter values for given sequence:</h2>"))
    output$param_values <- renderTable(paramValues)
    output$aa_counts_heading <- renderUI(HTML("<h2>Amino acid for given sequence:</h2>"))
    output$aa_counts <- DT::renderDataTable(
      DT::datatable(
        aaCounts, options = list(
        pageLength = 25
       )
      )
    )
  })
}