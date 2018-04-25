library(stringi)
library(stringr)

cleanup_sequence <- function(aa_sequence) {
  cleaned_sequence <- stringi::stri_trans_toupper(stringi::stri_replace_all_charclass(aa_sequence, "\\p{WHITE_SPACE}", ""))
  return(cleaned_sequence)
}
get_chain_type <- function(aa_seq) {
  if(stringr::str_detect(aa_seq, 'EIK$')) {
    return('L')
  } else if(stringr::str_detect(aa_seq, 'TVSS$')) {
    return('H')
  } else {
    return(NULL)
  }
}

get_first_cys_position <- function(aa_seq) {
  cys_locations <- stringr::str_locate_all(aa_seq, 'C')[[1]]
  first_cys_position <- cys_locations[1, 1]
  return(as.integer(first_cys_position))
}

get_last_cys_position <- function(aa_seq) {
  cys_locations <- stringr::str_locate_all(aa_seq, 'C')[[1]]
  last_cys_position <- cys_locations[nrow(cys_locations), ncol(cys_locations)]
  return(as.integer(last_cys_position))
}

get_cdr_l1_sequence <- function(aa_seq) {
  pattern <- 'C(.{10,})?W.[QL]'
  match <- stringr::str_match(aa_seq, pattern)
  return(match[[2]])
}

# https://stackoverflow.com/questions/34807871/r-regmatches-and-stringr-str-extract-dragging-whitespaces-along


get_cdr_l2_sequence <- function(aa_seq, cdr_l1_sequence) {
  if (nchar(stringr::str_trim(cdr_l1_sequence)) == 0) {
    return(NULL)
  }
  pattern <- stringr::str_c(cdr_l1_sequence, '.{15}(.{7})')
  match <- stringr::str_match(aa_seq, pattern)
  return(match[[2]])
}

get_cdr_l3_sequence <- function(aa_seq) {
  pattern <- 'C.+C(.+)FG.G'
  match <- stringr::str_match(aa_seq, pattern)
  return(match[[2]])
}

get_cdr_l_chain_sequence_list <- function(aa_seq) {
  aa_seq_prepped <- cleanup_sequence(aa_seq)
  chain_type <- get_chain_type(aa_seq_prepped)
  if(chain_type != 'L') return(NULL)
  cdr1_l <- get_cdr_l1_sequence(aa_seq_prepped)
  cdr2_l <- get_cdr_l2_sequence(aa_seq_prepped, cdr1_l)
  cdr3_l <- get_cdr_l3_sequence(aa_seq_prepped)
  return(list(CDR1 = cdr1_l, CDR2 = cdr2_l, CDR3 = cdr3_l))
}

get_cdr_h1_sequence <- function(aa_seq) {
  pattern <- 'C.{4}(.+?)W[VIA]'
  match <- stringr::str_match(aa_seq, pattern)
  return(match[[2]])  
}

get_cdr_h2_sequence <- function(aa_seq, cdr_h1_sequence, cdr_h3_sequence) {
  pattern <- stringr::str_c(cdr_h1_sequence, '.{14}(.+).{32}', cdr_h3_sequence)
  match <- stringr::str_match(aa_seq, pattern)
  return(match[[2]])  
}

get_cdr_h3_sequence <- function(aa_seq) {
  pattern <- 'C.+C..(.+)WG.G'
  match <- stringr::str_match(aa_seq, pattern)
  return(match[[2]]) 
}

get_cdr_h_chain_sequence_list <- function(aa_seq) {
  aa_seq_prepped <- cleanup_sequence(aa_seq)
  chain_type <- get_chain_type(aa_seq_prepped)
  if(chain_type != 'H') return(NULL)
  cdr1_h <- get_cdr_h1_sequence(aa_seq_prepped)
  cdr3_h <- get_cdr_h3_sequence(aa_seq_prepped)
  cdr2_h <- get_cdr_h2_sequence(aa_seq_prepped, cdr1_h, cdr3_h)
  return(list(CDR1 = cdr1_h, CDR2 = cdr2_h, CDR3 = cdr3_h))
}

get_total_cysteine_count <- function(aa_seq) {
  aa_seq_prepped <- cleanup_sequence(aa_seq)
  total_cysteine_count <- stringr::str_count(aa_seq_prepped, 'C')
  return(total_cysteine_count)
}

get_cdr_sequence_liabilities <- function(aa_seq) {
  aa_seq_prepped <- cleanup_sequence(aa_seq)  
  liabilities <- c('NG', 'NM', 'NS', 'NT', 'DG', 'DS', 'DT', 'DD', 'DM', 'M', 'C')
  liability_counts <- stringr::str_count(aa_seq_prepped, liabilities)
  names(liability_counts) <- liabilities
  return(stringr::str_c(stringr::str_c(names(liability_counts), liability_counts, sep = ':'), collapse = ', '))
}

highlight_liabilities_in_cdr  <- function(cdr_aa_seq) {
  liabilities <- c('NG', 'NM', 'NS', 'NT', 'DG', 'DS', 'DT', 'DD', 'DM', 'M', 'C')
  cdr_highlighted_liabilities <- cdr_aa_seq
  for (liability in liabilities) {
    cdr_highlighted_liabilities <- stringr::str_replace_all(cdr_highlighted_liabilities, liability, stringr::str_c('<span style="color:red">', liability, '</span>'))
  }
  return(cdr_highlighted_liabilities)
}

get_html_formatted_sequence <- function(cdr_sequence_list, aa_seq) {
  aa_seq_prepped <- cleanup_sequence(aa_seq)
  CDR1 <- cdr_sequence_list$CDR1
  CDR2 <- cdr_sequence_list$CDR2
  CDR3 <- cdr_sequence_list$CDR3
  CDR1_liabilities_html <- highlight_liabilities_in_cdr(CDR1)
  CDR2_liabilities_html <- highlight_liabilities_in_cdr(CDR2)
  CDR3_liabilities_html <- highlight_liabilities_in_cdr(CDR3)
  html_formatted_sequence <- stringr::str_replace(aa_seq_prepped, CDR1, stringr::str_c('<u><b>', CDR1_liabilities_html, '</b></u>'))
  html_formatted_sequence <- stringr::str_replace(html_formatted_sequence, CDR2, stringr::str_c('<u><b>', CDR2_liabilities_html, '</b></u>'))
  html_formatted_sequence <- stringr::str_replace(html_formatted_sequence, CDR3, stringr::str_c('<u><b>', CDR3_liabilities_html, '</b></u>'))
  return(html_formatted_sequence)
}


get_cysteine_count <- function(aa_seq) {
  return(stringr::str_count(aa_seq, 'C'))
}

check_given_sequence <- function(aa_seq) {
  aa_seq_prepped <- cleanup_sequence(aa_seq)
  if(get_cysteine_count(aa_seq_prepped) != 2) {
    return(sprintf("Expected only two Cys residues. Detected %d!", get_cysteine_count(aa_seq_prepped)))
  }
  if(!get_chain_type(aa_seq_prepped) %in% c('H', 'L')) {
    return('Cannot determine the chain type!')
  }
  return(NULL)
}

