library(shiny)
fluidPage(
  titlePanel("Align and Analyse Sequences"),
  tags$div(HTML(
    "<h2>Purpose</h2>
    <p>Use alignment to compare sequences</p>
    <h2>Assumes:</h2>
    <ul>
      <li>Amino acid sequences</li>
      <li>Sequences are in either FASTA or identifier-tab-sequence format</li>
    </ul>")
  ),
  textAreaInput("sequences_to_align", "Paste Sequence", width = "1000px", height = "100px"),
  tags$br(),
  actionButton("btn_align_run", "Align"),
  htmlOutput("aa_alignment"),
  uiOutput("sequence_ids"),
  actionButton("btn_align_difference_run", "Align Differences"),
  htmlOutput("aa_alignment_differences")
)
