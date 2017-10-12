library(shinydashboard)
library(shiny)


function(request){
dashboardPage(
  
  #Adds logo to header and increase size of dashboard scroll
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
    tags$style(HTML(".sidebar {height: 200vh; overflow-y: auto; overflow-x: hidden;}"))

  ),
  skin = "blue",

  header = dashboardHeader(title = "FACS Assays"),
  sidebar = dashboardSidebar(disable = TRUE),
  body =  dashboardBody(
    column(width = 3,
           tabsetPanel(
             tabPanel("Pull Data",
                      
                      #Inputs for pulling data
                      selectInput("assay_type", "Select an assay type", choices = c("Pan T Cell")),
                      selectInput("experiment_name", "Select an experiment name", choices = get.experiments(), multiple = TRUE),
                      uiOutput("datatype_column_name"),
                      actionButton("submit", "Pull Data", class = "btn-primary")
             ),
             tabPanel("Subset Data",
               
                      # Inputs for subsetting the data
                      selectInput('donor_day_list', label = "Select donor day", choices ="", multiple = TRUE),
                      selectInput('antibody_id_list', label = "Select antibody ID", choices = "", multiple = TRUE),
                      selectInput('cd3_concs_list', label = "Select CD3 concentrations", choices = "", multiple = TRUE),
                      selectInput('antibody_concs_list', label = "Select antibody concentrations", choices = "", multiple = TRUE),
                      fluidRow(uiOutput("graphicAxis")),
                      actionButton("run", "Run Plot", class = "btn-primary")
             ),
             #Inputs for altering the plot aesthetics
             tabPanel("Plot Interaction",
                      br(),
                      box(title = "Aesthetic Controls", solidHeader = TRUE, collapsible = TRUE, 
                          collapsed = TRUE, width = 12, status = "primary",
                          textInput("plot_title", "Set Plot Title",  ""),
                          checkboxInput("withPoint", "Show points on graphic?"),
                          checkboxInput("greyScale", "Grey scale?"),
                          checkboxInput("errorBars", "Show Error Bars?", value = TRUE),
                          checkboxGroupInput("facetBy", "Facet Plot By :", 
                                             choices = c("AntiBody Concentration" = "antibody_concentration",
                                                         "CD3 Concentration" = "cd3_concentration"))
                      ),
                      box(title = "X-Axis Controls", solidHeader = TRUE, collapsible = TRUE, 
                          collapsed = TRUE, width = 12, status = "primary",
                          sliderInput("xTextAdj", "Angle", min = 0, max = 180, value = 75),
                          sliderInput("xAxisFont", "Font Size", min = 5, max = 15, value = 10)
                          ),
                      box(title = "Legend Control", solidHeader = TRUE, collapsible = TRUE, 
                          collapsed = TRUE, width = 12, status = "primary",
                          sliderInput("legendSize", "Font Size", min = 5, max = 11, value = 8)
                      ),
                      #Download Buttons
                      #Columns used for button alignment
                      box(title = "Downloads", solidHeader = TRUE, collapsible = TRUE, 
                          collapsed = TRUE, width = 12, status = "primary",
                          fluidRow(
                            column(width = 6, 
                               downloadButton("csv", "Download Data"))
                      ),
                      fluidRow(
                        column(width = 12,
                             checkboxInput("downloadLogo", "Include Logo?", value = TRUE))),
                      fluidRow(
                        column(width = 6,
                               downloadButton("plotDownload", "Download Experiments"))
                            
                      ),
                      br(),
                      fluidRow( 
                        column(width = 6, 
                               downloadButton("plotDownload_AntiB", "Download Antibodies"))
                        ),
                      br(),
                      fluidRow( 
                        column(width = 6, 
                               downloadButton("plotDownload_DonorDay", "Download Donor Day"))
                      )
                      )
                      )
             ) 
           ),
    # Graphics and table output
    column(9,
           #bookmarkButton(align = "right"),
           img(src='tusk.png', align = "right", width = "110px"),   # Adds logo to dashboard
           tabsetPanel(id = "tabs",
             tabPanel("By Experiment",
                      fluidRow(uiOutput("ggbarplotFacet", width = "100%", height = "600px"))
                      ),
             tabPanel("By Antibody",
                      checkboxInput("antiB_ExperimentSplit", label = h4("Split by experiment?")),
                      fluidRow(uiOutput("antibodyFacet", width = "100%", height = "600px"))
                      ),
             tabPanel("By Donor_Day",
                      checkboxInput("donor_ExperimentSplit", label = h4("Split by experiment?")),
                      fluidRow(uiOutput("donor_day", width = "100%", height = "600px"))
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
}
