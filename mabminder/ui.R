library(shiny)
library(stringr)

fluidPage(
  mainPanel(
    tabsetPanel(
      tabPanel("Log In",
               selectInput("user_name", 
                           "User Name", choices = c('', "michael.maguire@tusktherapeutics.com", "Sabrina.Boussouf@tusktherapeutics.com")),
               passwordInput("password", "Password"),
               actionButton("btn_login", "Log In"),
               actionButton("btn_logout", "Log Out"),
               textOutput("logged_status")
      ),
      tabPanel("Register Antibody",
               textInput("antibody_identifier", "Antibody Identifier"),
               selectInput("antibody_type", "Antibody type (IgG1, etc)", choices = c("", "BiTEs", "Chimeric human-murine IgG1", "Chimeric IgG1", "Chimeric IgG1κ", "Chimeric mouse/human IgG1/κ", "EGFR", "Human FaB", "Human IgG1", "Human IgG1/κ", "Human IgG2", "Human IgG2/κ", "Human IgG4", "Humanized IgG1", "Murine IgG2a")),
               selectInput("antibody_source", "Antibody Source", choices = c("", "Commercial therapeutic", "Public research antibody", "Tusk")),
               textInput("gene_name", "Target Gene Name"),
               textInput("source_database_url", "Source Database URL"),
               textAreaInput("hchain_sequence", "Heavy Chain Sequence", width = "1000px", height = "100px"),
               textAreaInput("lchain_sequence", "Light Chain Sequence", width = "1000px", height = "100px"),
               br(),
               actionButton("btn_load_ab", "Load"),
               textOutput("retval")
               ),
      tabPanel("View Data",
               DT::dataTableOutput("antibody_data_summary")
               ),
      tabPanel("Upload/Download File",
                selectInput("target_identifier_fileupload", "Target Name", choices = c("", "CD25", "CD38")),
                textInput("antibody_name_fileupload", "Antibody Name"),
                textAreaInput("document_description", "Document Description"),
                fileInput("file_upload", 'Choose RDS file', accept = c(".pdf", ".docx")),
                tags$hr(),
                tags$h2("File Download"),
                textOutput("file_uploaded"),
                uiOutput("select_download_filename"),
                downloadButton("download_file", label = "Download")
      ),
      tabPanel("Add Note To Antibody",
               uiOutput("ab_list_add_note_to_ab"),
               textAreaInput("txt_ab_note_text", "Antibody Note", width = "1000px", height = "100px"),
               actionButton("btn_add_ab_note", "Add Note"),
               textOutput("txto_loaded_ab_note_result")
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