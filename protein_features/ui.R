library(shiny)
fluidPage(
  titlePanel("Protein Features Calculation"),
  tags$div(HTML(
    "<h2>Purpose</h2>
    <p>Produce parameter calculations for a give protein sequence</p>
    <h2>Assumes:</h2>
    <ul>
      <li>The input sequence is in single-letter amino acid format.</li>
    </ul>")
  ),
  textAreaInput("aa_seq", "Paste Sequence", width = "1000px", height = "100px"),
  actionButton('btn_run', "Submit"),
  mainPanel(
    tableOutput("param_values"),
    tableOutput("aa_counts")
  )
)