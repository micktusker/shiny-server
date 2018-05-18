library(shiny)
fluidPage(
  titlePanel("Antibody Sequence Database"),
  tags$div(HTML(
    "<h2>Purpose</h2>
    <p>Load antibody sequences to a database for analysis</p>
    <h2>Assumes:</h2>
    <ul>
      <li>The input sequence is in single-letter amino acid format.</li>
    </ul>")
  ),
  textInput("ab_name", "Antibody Name"),
  textAreaInput("ab_seq", "Paste Antibody Sequence to Load", width = "1000px", height = "100px"),
  br(),
  actionButton('btn_load', "Submit"),
  textOutput('retval')
)
