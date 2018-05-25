SELECT create_function_comment_statement(
  'bix_udfs.get_features_for_genomic_location',
  ARRAY['TEXT', 'TEXT', 'TEXT', 'BIGINT', 'BIGINT'],
  'Return a JSONB array of all values for the given species, chromosome and feature type contained within the given and start and stop coordinates.',
  $$SELECT * FROM bix_udfs.get_features_for_genomic_location('homo_sapiens', 'X', 'variation', 136648193, 136660390);$$,
  'The allowable feature names are checked and if the given feature name is not recognised, ' ||
  'an exception is thrown. The recognised ENUMs are represented as an array and the values were ' || 
  'taken from this link: https://rest.ensembl.org/documentation/info/overlap_region ' ||
  'The returned JSON is an array of JSON objects and it can be very large.'
);

SELECT create_function_comment_statement(
  'bix_udfs.get_uniprot_fastas_for_species_gene',
  ARRAY['TEXT[]', 'TEXT'],
  'Given an array of species names and a gene name, return the amino acid sequences for each gene in FASTA format.',
  $$SELECT bix_udfs.get_uniprot_fastas_for_species_gene(ARRAY['homo_sapiens', 'mus_musculus'], 'CD38');$$,
  'This function gets its FASTA sequences from the UniProt REST API and not the Ensembl one. ' ||
  'It should be moved to the uniprot schema!');

SELECT create_function_comment_statement(
  'bix_udfs.get_ensembl_json',
  ARRAY['TEXT'],
  'Returns JSONB for a given URL extension',
  $$SELECT * FROM bix_udfs.get_ensembl_json('/lookup/id/ENSG00000157764?expand=1');$$,
  'This function is written in Python. ' ||
  'It centralizes all calls to the Ensembl REST API, see: https://rest.ensembl.org/documentation. ' ||
  'Individual PL/pgSQL functions use it to get specific JSONB return values. ' ||
  'The second part of the URL, *p_ext* is expected to be fully formed with the parameters ' || 
  'already inserted by the calling code. It requires the Python *requests* module to be installed.');
  
SELECT create_function_comment_statement(
  'bix_udfs.get_details_for_id_as_json',
  ARRAY['TEXT'],
  'Return details as JSONB for a given Ensembl identifier e.g. gene, transcript, protein.', 
  $$SELECT * FROM bix_udfs.get_details_for_id_as_json('ENSG00000157764');$$,
  'Notes: Only accepts Ensembl identifiers and throws an error if the given identifier does not begin with *ENS*. ' ||
  'Calls a stored Python FUNCTION ensembl.that does the actual REST API call. ' || 
  'See Ensembl REST API documentation: https://rest.ensembl.org/documentation/info/lookup');

SELECT create_function_comment_statement(
  'bix_udfs.get_details_for_symbol_as_json',
  ARRAY['TEXT', 'TEXT'],
  'Return details as JSONB for a given symbol, a gene name for example, and species name.',
  $$SELECT * FROM bix_udfs.get_details_for_symbol_as_json('CD38', 'mus_musculus');$$,
  'Takes the Latin name for *species*, *mus_musculus* or *homo_sapiens*. ' ||
  'See documentation https://rest.ensembl.org/documentation/info/symbol_lookup');

SELECT create_function_comment_statement(
  'bix_udfs.get_variant_table_for_gene_symbol',
  ARRAY['TEXT', 'TEXT'],
  'Return a table of all the variants (excludes structural variants) for a given gene symbol and species.', 
  $$SELECT * FROM bix_udfs.get_variant_table_for_gene_symbol('CD38', 'homo_sapiens');$$,
  'It uses the gene symbol to extract the gene object JSON from which it gets the chromosome and ' ||
  'gene start and stop coordinates. It then calls the function *bix_udfs.get_features_for_genomic_location* ' ||
  'passing in the required gene location arguments, extracts some values from the JSON and returns a table. ' ||
  'An exception is raised if the gene symbol is not recognised.');

SELECT create_function_comment_statement(
  'bix_udfs.get_variation_info_as_json',
  ARRAY['TEXT', 'TEXT'],
  'Return details as JSONB for a given variation name and species name.', 
  $$SELECT * FROM bix_udfs.get_variation_info_as_json('rs7412', 'homo_sapiens');$$,
  'The returned JSONB object is information-rich for the variant.' ||
  'It provides position for the latest assembly, synonyms, consequences allele frequency and so on. ' ||
  'But it does not provide gene information, even for variants known to be intra-genic');
  
SELECT create_function_comment_statement(
  'bix_udfs.get_protein_ids_table_for_gene_ids',
  ARRAY['TEXT'],
  'Return a table of protein information for the given Ensembl gene ID.',
  $$SELECT * FROM bix_udfs.get_protein_ids_table_for_gene_ids('ENSG00000004468');$$,
  'The returned table contains all the Ensembl protein IDs for the input gene ID, ' ||
  'the translation length and a flag to inform if it is the canonical sequence for that gene. ' ||
  'It will throw an exception if the given gene ID is not recognised.');

SELECT create_function_comment_statement(
  'bix_udfs.get_protein_sequence_as_text_for_gene_id',
  ARRAY['TEXT'],
  'Return the canonical protein sequence for a given Ensembl gene ID.',
  $$SELECT bix_udfs.get_protein_sequence_as_text_for_gene_id('ENSG00000130203');$$,
  'This function sometimes returns a much longer sequence than the canonical Uniprot sequence. ' ||
  'For this reason, it is better to get this information from Uniprot');

SELECT create_function_comment_statement(
  'bix_udfs.get_gene_id_for_species_name',
  ARRAY['TEXT', 'TEXT'],
  'Return the Ensembl gene ID for a given gene name and species name.',
  $$SELECT bix_udfs.get_gene_id_for_species_name('homo_sapiens', 'CD38');$$,
  'It returns the first gene ID from the JSONB object returned by *bix_udfs.get_details_for_symbol_as_json*. ' ||
  'It uses SELECT INTO in non-strict mode so will not raise an error if the row count is <1 or >1.');
  
SELECT create_function_comment_statement(  
  'bix_udfs.get_fastas_for_species_gene',
  ARRAY['TEXT[]', 'TEXT'],
  'Return protein sequences in FASTA format for a given an array of species names and a gene name', 
  $$SELECT bix_udfs.get_fastas_for_species_gene(ARRAY['homo_sapiens', 'macaca_mulatta'], 'CD38');$$,
  'Used to get gene orthologs for a set of species for a particular gene. ' ||
  'The output can be used by various bioinformatics tools to do sequence comparisons.');

SELECT create_function_comment_statement(   
  'bix_udfs.get_xref_info_for_ensembl_id',
  ARRAY['TEXT'],
  'Return JSON containing details of all cross-references for the given Enseml ID.',  
  $$SELECT * FROM bix_udfs.get_xref_info_for_ensembl_id('ENSG00000004468');$$,
  'The given can be any sort of Ensembl ID (gene, protein transcript) for any species in Ensembl. ' ||
  'It is assumed to begin with *ENS* and error will be generated if the ID is not recognised.');

SELECT create_function_comment_statement( 
  'bix_udfs.get_xref_table_for_ensembl_id',
  ARRAY['TEXT'],
  'Return a table of desired values extracted from JSON with full cross-reference information for the given Ensembl ID.',
  $$SELECT * FROM bix_udfs.get_xref_table_for_ensembl_id('ENSG00000004468');$$,
  'The Ensembl ID can be any type of valid Ensembl ID, gene protein, etc. It is assumed to begin with *ENS*. ' ||
  'This function is very useful for getting cross-references for the given Ensembl ID in non-Ensembl stystems.');

SELECT create_function_comment_statement( 
  'bix_udfs.get_fasta_for_gene_from_uniprot',
  ARRAY['TEXT'],
  'Return the amino acid sequence for the given UniProt ID in FASTA format.',  
  $$SELECT * FROM bix_udfs.get_fasta_for_gene_from_uniprot('P28907');$$,
  'Use this function to get the definitive amino acid sequence for a protein. ' ||
  'Uses the UniProt REST API. Should be moved to the UniProt schema.');

SELECT create_function_comment_statement( 
  'bix_udfs.get_uniprot_id_for_ensembl_gene_id',
  ARRAY['TEXT'],
  'Return the Uniprot ID for a given Ensembl gene ID.', 
  $$SELECT * FROM bix_udfs.get_uniprot_id_for_ensembl_gene_id('ENSG00000004468');$$,
  'This function throws an error if there is more than one UniProt ID associated with ' ||
  'the Ensembl gene ID. For example, for the mouse verion of CD38, its Ensembl ID *ENSMUSG00000029084* ' ||
  'throws *ERROR:  query returned more than one row*.');

SELECT create_function_comment_statement( 
  'bix_udfs.get_uniprot_id_array_for_ensembl_gene_id',
  ARRAY['TEXT'],
  'Return an array of UniProt IDs for the given Ensembl gene ID.',
  $$SELECT * FROM bix_udfs.get_uniprot_id_array_for_ensembl_gene_id('ENSG00000268895');$$,
  'The function *bix_udfs.get_uniprot_id_array_for_ensembl_gene_id* throws an error if the ' ||
  'given Ensembl gene ID is associated with more than one UniProt ID. This function deals ' ||
  'with this situation by returning an array of UniProt IDs. ' ||
  'It returns NULL if there are no matching UniProt IDs.');
  
SELECT create_function_comment_statement( 
  'bix_udfs.get_vep_for_variation_id',
  ARRAY['TEXT', 'TEXT'],
  'Return the Variant Effect Predictor JSONB array for a given species name and variation ID.',  
  $$SELECT * FROM bix_udfs.get_vep_for_variation_id('rs7412', 'homo_sapiens');$$,
  'The returned JSONB is an array that contains some complex nested objects. ' ||
  'This function call is often very slow so should be used with cautions and avoided if possible ' ||
  'because it is subject to timeout errors from the REST server.');
  
SELECT create_function_comment_statement('bix_udfs.get_details_for_id_array_as_json', 
                                         ARRAY['TEXT[]'], 
                                         'Returns an array of JSONB objects received from the Ensembl REST API for the input array of Ensembl IDs.', 
                                         $$SELECT * FROM bix_udfs.get_details_for_id_array_as_json(ARRAY['ENSG00000275026', 'ENSG00000232433', 'ENSG00000172967', 'ENSG00000237525', 'ENSG00000185640', 'ENSG00000276128', 'ENSG00000227230', 'ENSG00000243961']);$$, 
                                         'The function initialises an array of the same length as the argument array with empty JSONB objects' ||
                                         'Each element of the initialised array will be populated with the JSON returned by the REST API call (*bix_udfs.get_details_for_id_as_json*) or ' || 
                                         ' a JSONB indicating an error with that ID. The returned array has to be the same length as the input argument array. ' ||
					 'The inner block in the *FOREACH* loop traps exceptions thrown when the REST API returns an error. ' ||
					 'Currently, the type of error is not reported so it could be due to a bad ID (one that does not exist or that has been deprecated) ' ||
					 'or due to a server-side API error.' ||
					 'The *PERFORM PG_SLEEP(1);* code line is added to ensure that the REST API does not throw an over-use error.');

SELECT create_function_comment_statement(
	'bix_udfs.get_xref_for_name_as_jsonb',
	ARRAY['TEXT'],
	'Returns Ensembl database cross-reference (xref) data as a JSONB array of xref objects for a give name.',
	$$SELECT get_xref_for_name_as_jsonb FROM bix_udfs.get_xref_for_name_as_jsonb('IGHV4-39');$$,
	'This function uses the Ensembl REST API to query for xrefs for a given name. ' ||
	'If the name is not found, an empty JSONB array is returned. ' ||
	'It should return xrefs for any name if they are available but it has only been used for gene names. ' ||
	'Some gene synonyms, e.g. |CD25|, are not recognised. For this example, |IL2RA| is recognised. ');

SELECT create_function_comment_statement(
	'bix_udfs.get_uniprot_accession_for_synonym',
	ARRAY['TEXT'],
	'Return the Uniprot accession, if available, for a given gene synonym.',
	$$SELECT get_uniprot_accession_for_synonym FROM bix_udfs.get_uniprot_accession_for_synonym('IGHV4-39');$$,
	'This function calls |bix_udfs.get_xref_for_name_as_jsonb| to return all the xref data from the Ensembl REST API. ' ||
	'It then filters the JSONB to identify the Unprot entry (if there is one) and proceeds to extract the Uniprot accession. ' ||
	'The Uniprot accession is ASSUMED to begin with P, Q or O (see: http://www.uniprot.org/help/accession_numbers). ' ||
	'The assumption that useful Uniprot accessions begin with P, Q or O may need to be re-visited.');

SELECT create_function_comment_statement(
	'bix_udfs.get_fasta_seq_as_aa_for_gene_synonym',
	ARRAY['TEXT'],
	'Return the amino acid FASTA sequence for a given gene name that has an entry in Ensembl xref.',
	$$SELECT get_fasta_seq_as_aa_for_gene_synonym FROM bix_udfs.get_fasta_seq_as_aa_for_gene_synonym('IL2RA');$$,
	'This function uses the given gene name (it can be any name that has an entry in Ensembl xrefs) to rerieve the Uniprot accession. ' ||
	'It gets this accession by calling the function |bix_udfs.get_uniprot_accession_for_synonym|. ' ||
	'This accession is then used as an argument to call function |bix_udfs.get_fasta_for_gene_from_uniprot| and ' ||
	'the amino acid sequence is returned in fASTA format. ' ||
	'Calling code code whould check for a NULL return value that indicates either that the given gene name synonym is absent from ' ||
	'Ensembl xrefs or that there is no Uniprot accession matching the pattern used by function |bix_udfs.get_uniprot_accession_for_synonym|.');
	
SELECT create_function_comment_statement(
	'bix_udfs.create_fasta_format',
	ARRAY['TEXT[]', 'TEXT', 'INTEGER'],
	'Create and return amino acid or nucleotide sequence in FASTA format.',
	$$SELECT create_fasta_format FROM bix_udfs.create_fasta_format(ARRAY['tr', 'O90777', 'O90777_9PLVG HIV-1 protease (Fragment) OS=Human immunodeficiency virus OX=12721 GN=HIV-1 protease PE=2 SV=1'], 'PQVTLWQRPIVTIKIGGQLKEALLDTGADDTVLEEMSLPGKWKPKMIGGIGGFIKVRQYDQVSIEICGHKAIGTVLIGPTPVNIIGRNLLTQLGCTLNF');$$,
	'The description line elements are given as a text array and the sequence wrap length has a default of 60 that can be changed by the calling code. ' ||
	'The new line character is specified as CHR(13). Note that when creating the regular expression named l_regexp NO space is permitted between the lower and upper ' ||
	'bounds and if given as {1, 60} an obscure error is generated.');

SELECT create_function_comment_statement(
	'bix_udfs.extract_sequence_from_fasta',
	ARRAY['TEXT'],
	'Extract just the nucleotide or amino acid sequence in upper-case with all white space removed from a standard FASTA record.',
	$$SELECT bix_udfs.extract_sequence_from_fasta('FASTA_RECORD_DEFINITION_LINE\nFASTA_SEQUENCE');$$,
	'This is a convenience function to extract just the sequence from a FASTA record. ' ||
    'The extracted sequence has all white space (leading, trainling or embedded) removed and is converted to upper-case. ' ||
    'The example call here does not include a real FASTA record because such a record throws JSON conversion errors in the documenter function. ' ||
    'A real FASTA record can be found here: http://www.uniprot.org/uniprot/O90777.fasta');
	