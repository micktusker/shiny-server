shinyServer(function(input, output) {
  ## CDR Section
  cdr_result <- reactive({
    if(nchar(input$aa_seq_cdr) < 1) {
      return(NULL)
    }
    isolate({
      input$aa_seq_cdr
      chain_type <- get_chain_type(input$aa_seq_cdr)
      if(chain_type == 'H') {
        cdr_sequence_list <- get_cdr_h_chain_sequence_list(input$aa_seq_cdr)
      } else if(chain_type == 'L') {
        cdr_sequence_list <- get_cdr_l_chain_sequence_list(input$aa_seq_cdr)
      }
      CDR1_liabilities <- get_cdr_sequence_liabilities(cdr_sequence_list$CDR1)
      CDR2_liabilities <- get_cdr_sequence_liabilities(cdr_sequence_list$CDR2)
      CDR3_liabilities <- get_cdr_sequence_liabilities(cdr_sequence_list$CDR3)
      ab_analysis <- data.frame(c('Chain Type', 'CDR1', 'CDR2', 'CDR3'), 
                                c(chain_type, cdr_sequence_list$CDR1, cdr_sequence_list$CDR2, cdr_sequence_list$CDR3),
                                c(NA, CDR1_liabilities, CDR2_liabilities, CDR3_liabilities))
      names(ab_analysis) <- c('Property', 'Result', 'Liabilities')
      return(ab_analysis)
    })
  })
  output$result <- renderTable({cdr_result()})
  seq_result <- reactive({
    if(nchar(input$aa_seq_cdr) < 1) {
      return(NULL)
    }
    isolate({
      chain_type <- get_chain_type(input$aa_seq_cdr)
      if(chain_type == 'H') {
        cdr_sequence_list <- get_cdr_h_chain_sequence_list(input$aa_seq_cdr)
      } else if(chain_type == 'L') {
        cdr_sequence_list <- get_cdr_l_chain_sequence_list(input$aa_seq_cdr)
      }
      html_formatted_sequence <- get_html_formatted_sequence(cdr_sequence_list, input$aa_seq_cdr)
      return(stringr::str_c('<h4>Sequence with CDRs and liabilities highlighted</h4><br>', html_formatted_sequence))
    })
  })
  output$aa_seq_formatted <- renderText(seq_result())
  ## Protein Features Section
  observeEvent(input$aa_run, {
    aa_seq_pa <- input$aa_seq_pa
    proteinResultsTables <- getProteinResultsTables(aa_seq_pa)
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
})