library(shiny)
fluidPage(
  titlePanel("Antibody CDR Analysis"),
  tags$div(HTML(
    "<h2>Purpose</h2>
    <p>Locate comlementarity determining regions (CDR) in antibody variable region (VR) sequences</p>
    <h2>Assumes:</h2>
    <ul>
      <li>Antibody VR sequence is human.</li>
      <li>It contains <b>two cysteine</b> residues.</li>
      <li>The sequence ends in either <b>EIK</b> for Light chain or <b>TVSS</b> for Heavy chain.</em>
    </ul>")
  ),
  textAreaInput("aa_seq", "Paste Sequence", width = "1000px", height = "100px"),
  submitButton(text = "Submit", icon = NULL),
  mainPanel(
    tableOutput("result"),
    htmlOutput("aa_seq_formatted"))
)
