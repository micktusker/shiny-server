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
               textInput("common_identifier", "Antibody Identifier"),
               selectInput("antibody_type", "Antibody type (IgG1, etc)", choices = c("", "BiTEs", "Chimeric human-murine IgG1", "Chimeric IgG1", "Chimeric IgG1κ", "Chimeric mouse/human IgG1/κ", "EGFR", "Human FaB", "Human IgG1", "Human IgG1/κ", "Human IgG2", "Human IgG2/κ", "Human IgG4", "Humanized IgG1", "Murine IgG2a")),
               selectInput("antibody_source", "Antibody Source", choices = c("", "Commercial therapeutic", "Public research antibody", "Tusk antibody")),
               textInput("gene_name", "Target Gene Name"),
               textInput("source_database_url", "Source Database URL"),
               textAreaInput("hchain_sequence", "Heavy Chain Sequence", width = "1000px", height = "100px"),
               textAreaInput("lchain_sequence", "Light Chain Sequence", width = "1000px", height = "100px"),
               br(),
               actionButton('btn_load_ab', "Load"),
               textOutput('retval')
               ),
      tabPanel("Upload File",
                selectInput("common_identifier", "Antibody Name", choices = c("", "AB1", "AB2", "...")),
                textAreaInput("document_description", "Document Description"),
                fileInput("file_upload", 'Choose RDS file', accept = c(".pdf", ".docx")),
                textOutput("file_uploaded")
      )
    )
  )
)