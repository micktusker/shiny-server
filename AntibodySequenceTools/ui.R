library(shiny)

fluidPage(
  mainPanel(
    tabsetPanel(
      tabPanel("CDR Analysis", 
                textAreaInput("aa_seq_cdr", "Paste Sequence", width = "1000px", height = "100px"),
                tableOutput("result"),
                htmlOutput("aa_seq_formatted")
      ),
      tabPanel("Protein Analysis", 
               textAreaInput("aa_seq_pa", "Paste Sequence", width = "1000px", height = "100px"),
               br(),
               actionButton('aa_run', "Analyse Protein"),
               uiOutput("param_values_heading"),
               tableOutput("param_values"),
               uiOutput("aa_counts_heading"),
               DT::dataTableOutput("aa_counts")
      ),
      tabPanel("Alignments", tags$p("To be implemented")),
      tabPanel("Clustering", tags$p("To be implemented"))
    )
  )
)