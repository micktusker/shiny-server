library(shiny)

fluidPage(
  titlePanel("Amino Acid Sequence Hydrophobicity Highlighter"),
  includeScript("www/sequence_hydrophobicity.js"),
  tags$div(HTML('
            <div id="description">
              <p>Hydrophobicity scores for individual amino acids is taken from reference: <a  href="https://www.sciencedirect.com/science/article/pii/0022283682905150">Kyte J, Doolittle RF (May 1982). "A simple method for displaying the hydropathic character of a protein".</a></p>
              <p>The amino acid symbols are colour-coded as follows:</p>
              <ul>
                <li>Highly hydrophobic amino acids: I, V, L, F, C <span style="background-color:#FF0000">are coded in red.</span></li>
                <li>Hydrophobic amino acids: M, A <span style="background-color:#FFA500">are coded in orange.</span></li>
                <li>Hydrophillic amino acids: G, T, S, W, Y, P <span style="background-color:#00FFFF">are coded in acqua.</span></li>
                <li>Highly hydrophillic amino acids: H, N, D, E, Q, K, R <span style="background-color:#0000FF">are coded in blue.</span></li>
              </ul>
            </div>
            <h1>Paste the amino acid sequence here:</h1>
            <textarea id="aa_sequence" rows=4 cols=90></textarea>
            <br />
            <input type="button" value="Clear" onclick="eraseText();">
            <input type="button" value="Calculate" onclick="writeMarkedUpSequenceResults();">
            <div id="seq_hydrophobicity">
              <p>Output</p>
            </div>'))
)