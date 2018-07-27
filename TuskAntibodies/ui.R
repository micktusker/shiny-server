library(shiny)
library(stringr)

fluidPage(
  mainPanel(
    tabsetPanel(
      tabPanel("View Data",
               actionButton("btn_pulldata", "Pull Data"),
               DT::dataTableOutput("antibody_data_summary")
      ),
      tabPanel("Search Database",
               textInput("txt_ab_name_search_db", "Return details for antibody name"),
               DT::dataTableOutput("dt_ab_name_search_db"),
               actionButton("btn_ab_name_search_db", "Search for Antibody"),
               textAreaInput("txta_ab_seq_search_db", "Paste Antibody Antibody Sequence", width = "1000px", height = "100px"),
               DT::dataTableOutput("dt_ab_seq_search_db"),
               actionButton("btn_ab_seq_search_db", "Search for Exact Antibody Sequence"),
               textAreaInput("txta_ab_seq_search_subseq_db", "Search for a Sub-sequence", width = "1000px", height = "100px"),
               DT::dataTableOutput("dt_ab_seq_search_subseq_db"),
               actionButton("btn_ab_seq_search_subseq_db", "Search for Sub-Sequence")
      )
    )
  )
)