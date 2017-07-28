library(shinydashboard)
library(shiny)

## TO DO : reimplement the select options from the database

dashboardPage(
  dashboardHeader(title = "FACS Assays"),
  dashboardSidebar(disable = TRUE),
  dashboardBody(
      column(width = 3,
           tabsetPanel(
             tabPanel("Pull Data",
                      
                      #Inputs for pulling data
                       selectInput("assay_type", "Select an assay type", choices = c("Pan T Cell")),
                       selectInput("experiment_name", "Select an experiment name", choices = get.experiments()),
                      #selectInput("datatype_column_name", "Select a data type", choices =  ""),
                      uiOutput("datatype_column_name"),
                       actionButton("submit", "Submit", class = "btn-primary")
           ),
           tabPanel("Subset Data",
           
                   # Inputs for subsetting the data
                   selectInput('donor_day_list', label = "Select donor day", choices ="", multiple = TRUE),
                   selectInput('antibody_id_list', label = "Select antibody ID", choices = "", multiple = TRUE),
                   selectInput('cd3_concs_list', label = "Select CD3 concentrations", choices = "", multiple = TRUE),
                   selectInput('antibody_concs_list', label = "Select antibody concentrations", choices = "", multiple = TRUE),
                   
                   actionButton("subset", "Run Plot", class = "btn-primary")
                   ),
           tabPanel("Plot Aesthetics",
                    textInput("plot_title", "Set Plot Title",  ""),
                    checkboxInput("withPoint", "Show points on graphic?"),
                    checkboxInput("errorBars", "Show Error Bars?", value = TRUE),
                    checkboxGroupInput("facetBy", "Facet Plot By :", choices = c("AntiBody Concentration" = "antibody_concentration",
                                                                                 "CD3 Concentration" = "cd3_concentration")),
                    #Download Buttons
                    fluidRow(downloadButton("csv", "Download CSV"),
                             downloadButton("plotDownload", "Download Plot"))
                    )
           ) 
    ),
    column(9,
           img(src='tusk.png', align = "right", width = "110px"),   #adds logo to dashboard
           tabsetPanel(
             tabPanel("Plot",
                      
                      fluidRow(plotOutput("ggbarplotFacet", width = "100%", height = "600px"))
             ),
             tabPanel("Interaction Plot",
                      plotly::plotlyOutput('interactionPlot')
                      ),
             tabPanel("Data",
                      DT::dataTableOutput("subsetResult")
                      )
           )
    )
    
  )
)

