library(shiny)
shinyUI(fluidPage(
  titlePanel("Pan T Cell Assay"),
  
  fluidRow(
    selectInput("data_column", "Select a data column", c('viable_cells','cd4_mfi_cd137','cd4_mfi_proliferation','cd4_mfi_cd25','cd4_percent_proliferation','cd4_percent_cd25','cd4_percent_cd137','cd8_mfi_cd137','cd8_mfi_proliferation','cd8_mfi_cd25','cd8_percent_proliferation','cd8_percent_cd25','cd8_percent_cd137','cd4_cell_number','cd8_cell_number','sample_identifier'
               )),
    selectInput("experiment_name", "Select an experiment name", c('TSK01_vitro_024')),
    selectInput("source_file_description", "Select the source file name", c('TSK01_vitro_024 donor 1 day3 FACS analysis', 'TSK01_vitro_024 donor 2 day3 FACS analysis', 'TSK01_vitro_024 donor 1 day4 FACS analysis')),
    actionButton("submit", "Submit", class = "btn-primary")
    ),
  mainPanel(plotOutput("barplot")),
  mainPanel(DT::dataTableOutput("result"))
))