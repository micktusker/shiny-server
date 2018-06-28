-- Structured documentation is added to all user_defined_crud_functions by executing the function "public.create_function_comment_statement".

SELECT create_function_comment_statement(
	'user_defined_crud_functions.add_antibody_document_record',
	ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT'],
	'Adds details of a document that is stored on the file share and associated with an antibody to the database.',
	$$SELECT add_antibody_document_record FROM user_defined_crud_functions.add_antibody_document_record('DARATUMUMAB', '1234ABC', 'dummy.pdf', 'A test entry that does not refer to a real document')$$,
	'The arguments to this function are the (1) antibody name (common_identifier), (2) the file checksum (calculated by the client, the tools::md5sum in R, for example), ' ||
	'(3) the document name and (4) a description of the document. Note: The document itself is stored on the file share and not in the database itself. ' ||
	'This function can only be executed by a user in the usernames table, admin accounts will generate a foreign key violation error when executing it. ' ||
	'The database schema allows a many-to-many relationship between but this function associated a document with a single antibody. ' ||
	'Client code can call this function repeatedly to allow implement the many-to-many relationship.');
	
SELECT create_function_comment_statement(
	'user_defined_crud_functions.create_new_antibody_sequence_entry',
	ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'],
	'Create an antibody-sequence combination in the database.',
	$$SELECT create_new_antibody_sequence_entry FROM  user_defined_crud_functions.create_new_antibody_sequence_entry('daratumumab', 'Human IgG1/κ', 'CD38', 'Commercial therapeutic', 'https://www.kegg.jp/entry/D10777', 'EIVLTQSPAT LSLSPGERAT LSCRASQSVS SYLAWYQQKP GQAPRLLIYD ASNRATGIPARFSGSGSGTD FTLTISSLEP EDFAVYYCQQ RSNWPPTFGQ GTKVEIKRTV AAPSVFIFPPSDEQLKSGTA SVVCLLNNFY PREAKVQWKV DNALQSGNSQ ESVTEQDSKD STYSLSSTLTLSKADYEKHK VYACEVTHQG LSSPVTKSFN RGEC', 'L');$$,
	'This is a high-level and big function that the client can call to create a new antibody record in the datatabase '  ||
	'that associates the antibody information with the given sequence. It can only be called by a user defined in the usernames table (not an admin). '
	'Its arguments are (1) the antibody name, (2) the isotype, (3) the gene target name (can be null), (4) where the antibody is from (commercial, in-house, etc ' ||
	'(5) the URL where the general information and sequence is taken from, (6) the antibody amino acid sequence and and (7) the chain type (H or L). ' ||
	'The casing is normalised to upper and white space is removed from both the amino acid sequence and the antibody name so that, for example, daratumumab and Daratumumab are treated as the same identifier and are both stored as DARATUMUMAB. ' ||
	'This function delegates the insertion of the antibody information and antibody sequences to |load_antibody_information| and |load_amino_acid_sequence|, respectively. ' ||
	'It has been designed to ignore replicate entries in either the information or amino acid sequence table but it does report them and writes the report to |data_load_logs|. ' ||
	'If either the same amino acid sequence or antibody name (common_identifer) is passed as an argument, the duplicate is ignored but if the other (sequence or common identifier) ' ||
	'is not a duplicate, it is loaded. The function is designed to be robust and to insert the given into whatever tables it can. As an example, each antibody has two sequences, ' ||
	'the heavy and the light chains. If the heavy chain is loaded for an antibody that is not in the database, the |antibody_information|, the |amino_acid_sequences| and the |sequences_to_information| ' ||
	'join table each have have a row inserted. When the light chain is then loaded with the same antibody identifer, only the |amino_acid_sequences| and the |sequences_to_information| tables have new rows added to them. ' ||
	'When this function is called, there should always be a resulting entry in the |data_load_logs| table and errors are prominently displayed with a message beginning with |ERROR|.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_aa_seq_ids_for_ab_name',
	ARRAY['TEXT'],
	'For a given antibody name (common identifier), return all sequences IDs attached to it.',
	$$SELECT get_aa_seq_ids_for_ab_name FROM  user_defined_crud_functions.get_aa_seq_ids_for_ab_name('daratumumab');$$,
	'This function does NOT return the amino acid sequences themselves, it returns the MD5 hash values calculated for ' ||
	'the amino acid sequences that are used to uniquely identify the sequences. This function is intnded for primarily internal use. ' ||
	'To retrieve the amino sequences themselves, client code should call the function |get_aa_sequences_for_ab_name|.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_aa_sequences_for_ab_name',
	ARRAY['TEXT'],
	'For a given antibody name (common identifier), return all sequences and sequence chain types attached to it.',
	$$SELECT * FROM user_defined_crud_functions.get_aa_sequences_for_ab_name('daratumumab');$$,
	'Use this function to retrieve all sequences (if any) associated with the given antibody name. ' ||
	'The function allows for case and white space.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_cleaned_amino_acid_sequence',
	ARRAY['TEXT', 'TEXT'],
	'Given a single-letter amino acid sequence and an optional string of allowable extra single characters, determine its validity and, if valid, return the sequence in upper-case with all white space removed.',
	$$SELECT get_cleaned_amino_acid_sequence FROM user_defined_crud_functions.get_cleaned_amino_acid_sequence('PQVTLWQRPI VTIKIGGQLK EALLDTGADD TVLEEMSLPG KWKPKMIGGIX', 'X');$$,
	'This function is used to check that the given single-letter amino acid sequence is valid. Optional characters in addition to the default 20 amino acid symbols can be added. ' ||
	'The given sequence is converted to upper-case, white space is removed and a regular expression is constructed to check validity. If valid, ' ||
	'the converted sequence is returned. If invalid, an exception is thrown.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_sequence_hash_id',
	ARRAY['TEXT'],
	'Returns the MD5 hash ID for a given single letter amino acid sequence.',
	$$SELECT get_cleaned_amino_acid_sequence FROM user_defined_crud_functions.get_sequence_hash_id('PQVTLWQRPI VTIKIGGQLK EALLDTGADD TVLEEMSLPG KWKPKMIGGI');$$,
	'It calculates the MD5 hash on the return value of the function |get_cleaned_amino_acid_sequence| and is therefore insensitive to case and white space. ' ||
	'Because it calls |get_cleaned_amino_acid_sequence| without additional allowable characters, it will raise an exception for any argument ' ||
	'other than a string of the standard 20 single-letter amino acid symbols. The hash value is used throughout the database to determine the identity '
	'of antibody amino acid sequences so this function is very important.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.is_ab_common_identifier_present',
	ARRAY['TEXT'],
	'Determines if the given antibody identifier exists in the database.',
	$$SELECT is_ab_common_identifier_present FROM user_defined_crud_functions.is_ab_common_identifier_present('abraxumab');$$,
	'General utility function. ' ||
	'Performs a search independent of case and white space for the given identifier. '
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.load_amino_acid_sequence',
	ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT'],
	'Add a row for a sequence to table |amino_acid_sequences| and return a Boolean indicating outcome.',
	$$SELECT load_amino_acid_sequence FROM user_defined_crud_functions.load_amino_acid_sequence('e76e6ff7d3b7cf433e998243edc01509', 'EIVLTQSPAT LSLSPGERAT LSCRASQSVS SYLAWYQQKP GQAPRLLIYD ASNRATGIPARFSGSGSGTD FTLTISSLEP EDFAVYYCQQ RSNWPPTFGQ GTKVEIKRTV AAPSVFIFPPSDEQLKSGTA SVVCLLNNFY PREAKVQWKV DNALQSGNSQ ESVTEQDSKD STYSLSSTLTLSKADYEKHK VYACEVTHQG LSSPVTKSFN RGEC', 'L', 'dummy_L');$$,
	'Given the the hash ID for the sequence, the amino acid sequence, the chain type and sequence name, create a record in table |amino_acid_sequences|. ' ||
	'This is an internal function that is NOT meant to be called by client code. It should only be used for an amino acid sequence that has been returned by function ' ||
	'|get_cleaned_amino_acid_sequence| with a hash ID calculated from this value.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.load_antibody_information',
	ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'],
	'Add a row for an antibody to the table |antibody_information| and return a Boolean indicating if the row was added.',
	$$SELECT load_antibody_information FROM user_defined_crud_functions.load_antibody_information('DARATUMUMAB', 'Human IgG1/κ', 'CD38', 'Commercial therapeutic', 'https://www.ebi.ac.uk/chembl/compound/inspect/CHEMBL1743007');$$,
	'Given the antibody name, type, gene target, source and source URL, create a record in table |antibody_information|. ' ||
	'This is an internal function that is NOT meant to be called by client code. It takes the antibody name as given and does no white space or case ' ||
	'normalisation so that |daratumumab| and |Daratumumab| will be trated as distinct names.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.remove_antibody_record',
	ARRAY['TEXT'],
	'Remove an antibody and all its associated sequences from the database for a given antibody name.',
	$$SELECT remove_antibody_record FROM user_defined_crud_functions.remove_antibody_record('OBILTOXAXIMAB');$$,
	'The function does a case- and white space-independent operation for the given antibody name and retrns a string summarising what was done. ' ||
	'If the given identifier is not found, it will inform the caller of that and do a no-op on the database. ' ||
	'Use this function with caution because it will remove records from the database. ' ||
	'Table triggers will ensure that the deleted data is written to the audit table |update_delete_log|. ' ||
	'The audit table records the username and the timestamp for the delete operations so that the operation is fully tracked by the system. ' ||
	'TO DO: Need to check this function again, does a simple DELETE using the antibody common_identifer perform the same task by using foreign key ' ||
	'DELETE CASCADE? Also need to ensure that the triggers are doing the audit correctly.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.load_antibody_document',
	ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT'],
	'Upload a document to the server and associate it with an antibody record in the database.',
	$$SELECT user_defined_crud_functions.load_antibody_document('DARATUMUMAB', 'abc123def', 'Dummy Document.doc', 'A dummy test for a non-existent document.');$$,
	'The webpage uploads a file to the server and this function stores about the uploaded file to the database. ' ||
	'The client calculates the file checksum and this is used to assign a unique identifer to the uploaded file.' ||
	'The uploaded file is associated with an antibody by a simultaneous uptload to the join table |documents_to_antibodies|.'
);


SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_uploaded_filenames',
	NULL,
	'Return a list of names for all files stored on the server.',
	$$SELECT user_defined_crud_functions.get_uploaded_filenames();$$,
	'Used to populate the Shiny webpage file download selection with a sorted list of all files stored on the server. ' ||
	'How the file list is displayed on the webpage to the user will be reviewed.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.add_note_to_antibody',
	ARRAY['TEXT', 'TEXT'],
	'Add a descriptive note to an antibody record in the database.',
	$$SELECT user_defined_crud_functions.add_note_to_antibody('DARATUMUMAB', 'This is a test note!');$$,
	'Used to attach user-defined descriptive notes to database'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.load_aa_sequence_and_ab_join',
	ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT'],
	'Insert an amino acid sequence row and associated with the given antibody identifer.',
	$$SELECT user_defined_crud_functions.load_aa_sequence_and_ab_join('TSK031001', 'QVQLVQSGAEVKKPGASVKVSCKASGYTFTGYYMHWVRQAPGQGLEWMGSINPNSGGTNYAQKFQGRVTMTRDTSISTAYMELSRLRSDDTAVYYCARDGLMDVWGQGTAVTVSS', 'H')$$,
	'Not to be confused with function |load_amino_acid_sequence| which is not meant to be called externally. ' ||
	'This function is meant to be called externally and can be used to load antibody amino acide sequences ' ||
	'independently of the antibody information. It also updates the table |sequences_to_information| that associated sequences ' ||
	'with antibody identifers. Note that the sequence name is optional and if not provided, it is generated automatically by ' ||
	'concatenating the antibody name with an underscore and the chain type. It uses the COALESCE function to determine if the sequence name is NULL.'
);

SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_sequence_hash_ids',
	ARRAY['TEXT[]'],
	'Return an array of MD5 hash IDs for an array of amino acid sequences.',
	$$SELECT user_defined_crud_functions.get_sequence_hash_ids(ARRAY['QVQLVQSGAEVKKPGSSVKVSCKASGGTFSSLAI', 'WVRQAPGQGLEWMGGIIPIFGDASYAQKF']);$$,
	'This function has a singular version |get_sequence_hash_id| that it calls as it loops over the input array and builds the output array.'
);


-- Documentation for functions to display output
SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_ab_data_for_aa_seq',
	ARRAY['TEXT'],
	'Given an amino acid sequence, return all antibody information -if any- associated with that sequence as JSONB.',
	$$SELECT user_defined_crud_functions.get_ab_data_for_aa_seq('EIVLTQSPATLSLSPGERATLSCRASQSVSSYLAWYQQKPGQAPRLLIYDASNRATGIPARFSGSGSGTDFTLTISSLEPEDFAVYYCQQSSNWPRTFGQGTKVEIKRTVAAPSVFIFPPSDEQLKSGTASVVCLLNNFYPREAKVQWKVDNALQSGNSQESVTEQDSKDSTYSLSSTLTLSKADYEKHKVYACEVTHQGLSSPVTKSFNRGEC');$$,
	'This function will return information on an antibody from the |antibody_information| table if the antibody is assciated with ' ||
	'the input sequence via an entry in the join table |sequences_to_information|. Because a sequence can be associated with more than one antibody, the function ' ||
	'first gets an array of allantibody common identifiers associated with the sequence and then uses this array in the inner-most query to ensure that all associated ' ||
	'antibody rows are returned. ' ||
	'Although this function can be called directly, it is meant to be called by function |get_seq_data_for_aa_seq| which combines antibody and sequence information ' ||
	'into one output table.');


SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_seq_data_for_aa_seq',
	ARRAY['TEXT'],
	'Given an amino acid sequence, return all information -if any- associated with that sequence as JSONB.',
	$$SELECT user_defined_crud_functions.get_seq_data_for_aa_seq('EIVLTQSPATLSLSPGERATLSCRASQSVSSYLAWYQQKPGQAPRLLIYDASNRATGIPARFSGSGSGTDFTLTISSLEPEDFAVYYCQQSSNWPRTFGQGTKVEIKRTVAAPSVFIFPPSDEQLKSGTASVVCLLNNFYPREAKVQWKVDNALQSGNSQESVTEQDSKDSTYSLSSTLTLSKADYEKHKVYACEVTHQGLSSPVTKSFNRGEC');$$,
	'Columns are selected from the |amino_acid_sequences| table. If the MD5 calculated for the input amino acid sequence does not match a primary ' ||
	'key in this table a JSONB with a single key is returned to indicate this (COALESCE call does this). '||
	'Although this function can be called directly, it is meant to be called by function |get_seq_data_for_aa_seq| which combines antibody and sequence information ' ||
	'into one output table.');


SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_all_data_for_aa_seq',
	ARRAY['TEXT'],
	'Return a table containing a summary of sequence and antibody information available for a given amino acid sequence.',
	$$SELECT * FROM user_defined_crud_functions.get_all_data_for_aa_seq('EIVLTQSPATLSLSPGERATLSCRASQSVSSYLAWYQQKPGQAPRLLIYDASNRATGIPARFSGSGSGTDFTLTISSLEPEDFAVYYCQQSSNWPRTFGQGTKVEIKRTVAAPSVFIFPPSDEQLKSGTASVVCLLNNFYPREAKVQWKVDNALQSGNSQESVTEQDSKDSTYSLSSTLTLSKADYEKHKVYACEVTHQGLSSPVTKSFNRGEC');$$,
	'This function combines (UNION) the JSONB output from functions |get_ab_data_for_aa_seq| and |get_seq_data_for_aa_seq| into a single two-column output table. ' ||
    'Client code can call this function to determine what information, if any, is stored in the database for the input sequence.');

SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_ab_common_identifier_for_given_name',
	ARRAY['TEXT'],
	'Perform a case-insensitive search to return the |common_identifier| for a given antibody name or synonym or return NULL if it does not exist.',
	$$SELECT user_defined_crud_functions.get_ab_common_identifier_for_given_name('nivolumab');$$,
	'This function first does a case-insensitive search of the |common_identifier| primary key column of the table |antibody_information| and ' ||
	'reurns the common identifier if it finds it. Otherwise it searches the table |antibody_names_lookup| and returns the a common identifier if the given ' ||
	'name maps to a synonym in the column ||alternative_name|.'
);



SELECT create_function_comment_statement(
	'user_defined_crud_functions.get_ab_data_for_given_ab_name',
	ARRAY['TEXT'],
	'Return data about the given antibody name as JSONB.',
	$$SELECT * FROM user_defined_crud_functions.get_ab_data_for_given_ab_name('nivolumab');$$,
	'This function returns selected data on the given antibody name as JSONB. It uses the function |get_ab_common_identifier_for_given_name| ' ||
	'to resolve the given name to a common antibody identifier if possible to allow defined antibody synonyms to be used. ' ||
	'Although it can be called independently, it is meant to be called by |get_all_ab_data_for_given_ab_name| which returns a table ' ||
	'that combines general antibody with its associated sequences.'
);


