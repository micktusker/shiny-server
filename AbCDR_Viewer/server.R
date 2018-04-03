library(shiny)


# Define server logic required to generate and plot a random distribution
shinyServer(function(input, output) {
  result <- reactive({
    if(nchar(input$aa_seq) < 1) {
      return(NULL)
    }
    isolate({
      input$aa_seq
      chain_type <- get_chain_type(input$aa_seq)
      if(chain_type == 'H') {
        cdr_sequence_list <- get_cdr_h_chain_sequence_list(input$aa_seq)
      } else if(chain_type == 'L') {
        cdr_sequence_list <- get_cdr_l_chain_sequence_list(input$aa_seq)
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
  output$result <- renderTable({result()})
})
