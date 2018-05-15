library(jsonlite)

getProteinResultsJson <- function(aa_seq) {
  retval <- system2("./run_get_protein_results_json.py", aa_seq, stdout = TRUE, stderr = TRUE)
  return(jsonlite::fromJSON(retval))
}


# simply dividing the Molar Extinction Coefficient by the molecular weight

getProteinResultsTables <- function(aa_seq) {
  proteinResultsList <- getProteinResultsJson(aa_seq)
  getParamsDF <- function() {
    paramCalculations <- c(proteinResultsList$molecular_weight,
                           proteinResultsList$isoelectric_point,
                           proteinResultsList$extinction_coefficient_reduced_cysteines,
                           proteinResultsList$extinction_coefficient_disulphide_bridges,
                           absorbance_reduced_cysteine <- proteinResultsList$extinction_coefficient_reduced_cysteines/proteinResultsList$molecular_weight,
                           absorbance_disulphide_bridges <- proteinResultsList$extinction_coefficient_disulphide_bridges/proteinResultsList$molecular_weight)
    paramNames <- c('Molecular Weight',
                    'Isoelectric Point',
                    'Extinction Coefficient Reduced Cysteine', 
                    'Extinction Coefficient Disulphide Bridges',
                    'Absorbance 0.1% Reduced Cysteine',
                    'Absorbance 0.1% Disulphide Bridges')
    df <- data.frame(paramNames, paramCalculations)
    names(df) <- c('Parameter', 'Value')
    return(df)
  }
  getAminoAcidCountsDF <- function() {
    aminoAcidCounts <- proteinResultsList$amino_acid_count
    df <- data.frame(t(data.frame(aminoAcidCounts)))
    df['Amino Acid'] <- rownames(df)
    row.names(df) <- NULL
    names(df) <- c('Count', 'Amino Acid')
    df <- df[c(2, 1)]
    return(df)
  }
  return(list(getParamsDF(), getAminoAcidCountsDF()))
}