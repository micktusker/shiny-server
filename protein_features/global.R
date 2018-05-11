library(jsonlite)

getProteinResultsJson <- function(aa_seq) {
  retval <- system2("./run_get_protein_results_json.py", aa_seq, stdout = TRUE, stderr = TRUE)
  return(jsonlite::fromJSON(retval))
}


getProteinResultsTables <- function(aa_seq) {
  proteinResultsList <- getProteinResultsJson(aa_seq)
  getParamsDF <- function() {
    paramCalculations <- c(proteinResultsList$molecular_weight, 
                           proteinResultsList$extinction_coefficient_reduced_cysteines, 
                           proteinResultsList$extinction_coefficient_disulphide_bridges)
    paramNames <- c('Molecular Weight', 
                    'Extinction Coefficient Reduced Cysteine', 
                    'Extinction Coefficient Disulphide Bridges')
    df <- data.frame(paramNames, paramCalculations)
    names(df) <- c('Parameter', 'Value')
    return(df)
  }
  getAminoAcidCountsDF <- function() {
    aminoAcidCounts <- proteinResultsList$amino_acid_count
    df <- data.frame(t(data.frame(aminoAcidCounts)))
    df['Amino Acid'] <- rownames(df)
    names(df) <- c('Count', 'Amino Acid')
    df <- df[c(2, 1)]
    return(df)
  }
  return(list(getParamsDF(), getAminoAcidCountsDF()))
}