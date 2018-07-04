DROP SCHEMA IF EXISTS user_defined_crud_functions CASCADE;
CREATE SCHEMA user_defined_crud_functions;
COMMENT ON SCHEMA user_defined_crud_functions IS 'Contains all functions that perform Create, Read, Update, and Delete operations on tables in schemas "ab_data" and "audit_logs".';

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_cleaned_amino_acid_sequence(p_amino_acid_sequence TEXT, p_extra_allowable_chars TEXT DEFAULT NULL)
RETURNS TEXT
AS
$$
DECLARE
  l_amino_acid_sequence TEXT := UPPER(REGEXP_REPLACE(p_amino_acid_sequence, '\s', '', 'g'));
  l_amino_acids TEXT := CONCAT('ACDEFGHIKLMNPQRSTVWY', p_extra_allowable_chars);
  l_regex TEXT := CONCAT('^[', l_amino_acids, ']+$');
BEGIN
  IF l_amino_acid_sequence ~ l_regex THEN
    RETURN l_amino_acid_sequence;
  ELSE
    RAISE EXCEPTION 'Given amino sequence contains unrecognised symbol(s).';
  END IF;
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_sequence_hash_id(p_ab_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_sequence_hash_id TEXT;
  l_ab_sequence TEXT;
BEGIN
  l_ab_sequence := user_defined_crud_functions.get_cleaned_amino_acid_sequence(p_ab_sequence);
  
  RETURN MD5(l_ab_sequence);
  
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;



-- Loading antibodies 
-- TO BE FIXED!!
-- test this function on Wed 13th June
CREATE OR REPLACE FUNCTION user_defined_crud_functions.load_antibody_information(p_common_identifier TEXT,
																		         p_antibody_type TEXT,
																		         p_target_gene_name TEXT,
													   					       p_antibody_source TEXT,
													   					       p_antibody_url TEXT)
RETURNS BOOLEAN
AS
$$
DECLARE
 l_new_record_created BOOLEAN;
BEGIN
  INSERT INTO ab_data.antibody_information(common_identifier, target_gene_name, antibody_type, antibody_source, antibody_url)
    VALUES(p_common_identifier, p_target_gene_name, p_antibody_type, p_antibody_source, p_antibody_url);
  l_new_record_created := TRUE;
  
  RETURN l_new_record_created;
  
EXCEPTION
  WHEN UNIQUE_VIOLATION THEN
    l_new_record_created := FALSE;
	
	RETURN l_new_record_created;
	
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;


CREATE OR REPLACE FUNCTION user_defined_crud_functions.load_amino_acid_sequence(p_amino_acid_sequence_hash_id TEXT, 
																				p_amino_acid_sequence TEXT, 
																				p_chain_type TEXT,
																				p_sequence_name TEXT)
RETURNS BOOLEAN
AS
$$
DECLARE
  l_new_record_created BOOLEAN;
BEGIN
  INSERT INTO ab_data.amino_acid_sequences(amino_acid_sequence_id, amino_acid_sequence, chain_type, sequence_name)
    VALUES(p_amino_acid_sequence_hash_id, p_amino_acid_sequence, p_chain_type, p_sequence_name);
  l_new_record_created := TRUE;
  
  RETURN l_new_record_created;
  
EXCEPTION
  WHEN UNIQUE_VIOLATION THEN
    l_new_record_created := FALSE;
	
	RETURN l_new_record_created;

END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.create_new_antibody_sequence_entry(p_common_identifier TEXT,
																						  p_antibody_type TEXT,
																						  p_gene_name TEXT,
													                                      p_antibody_source TEXT,
													                                      p_source_database_url TEXT,
																		                  p_antibody_sequence TEXT,
																		                  p_chain_type TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_common_identifier TEXT := TRIM(UPPER(p_common_identifier));
  l_antibody_sequence TEXT := user_defined_crud_functions.get_cleaned_amino_acid_sequence(p_antibody_sequence);
  l_antibody_sequence_hash_id TEXT := user_defined_crud_functions.get_sequence_hash_id(p_antibody_sequence);
  l_retval TEXT := 'Successful upload of record for antibody identifier "%s" and antibody sequence hash ID "%s". New information row created: "%s". New sequence row created: "%s"';
  l_new_information_record_created BOOLEAN;
  l_new_sequence_record_created BOOLEAN;
  l_sequence_name TEXT := CONCAT(l_common_identifier, '_', p_chain_type);
BEGIN
  l_new_information_record_created := user_defined_crud_functions.load_antibody_information(l_common_identifier, p_antibody_type, p_gene_name, p_antibody_source, p_source_database_url);
  l_new_sequence_record_created := user_defined_crud_functions.load_amino_acid_sequence(l_antibody_sequence_hash_id, l_antibody_sequence, p_chain_type, l_sequence_name);
  INSERT INTO ab_data.sequences_to_information(common_identifier, amino_acid_sequence_id)
    VALUES(l_common_identifier, l_antibody_sequence_hash_id);
  l_retval := FORMAT(l_retval, l_common_identifier, l_antibody_sequence_hash_id, l_new_information_record_created, l_new_sequence_record_created);
  INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
  RETURN l_retval;

EXCEPTION
  WHEN UNIQUE_VIOLATION THEN
    l_retval := FORMAT('Duplicate entry for antibody identifier "%s" and sequence hash ID "%s".', l_common_identifier, l_antibody_sequence_hash_id);
	INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
	
	RETURN l_retval;
	
  WHEN OTHERS THEN
    l_retval := FORMAT('ERROR: %s', SQLERRM);
	INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
	
	RETURN l_retval;
	
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_aa_seq_ids_for_ab_name(p_common_identifier TEXT)
RETURNS TABLE(amino_acid_sequence_id TEXT)
AS
$$
DECLARE
  l_common_identifier TEXT := UPPER(TRIM(p_common_identifier));
BEGIN
  RETURN QUERY
  SELECT
    aas.amino_acid_sequence_id
  FROM 
    ab_data.antibody_information ai
    JOIN
      ab_data.sequences_to_information sti
	  ON
	    ai.common_identifier = sti.common_identifier
    JOIN
      ab_data.amino_acid_sequences aas 
	  ON 
	    sti.amino_acid_sequence_id = aas.amino_acid_sequence_id
  WHERE
    ai.common_identifier = l_common_identifier;
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;
SELECT get_aa_seq_ids_for_ab_name FROM user_defined_crud_functions.get_aa_seq_ids_for_ab_name('OBILTOXAXIMAB');

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_aa_sequences_for_ab_name(p_common_identifer TEXT)
RETURNS TABLE(amino_acid_sequence TEXT, chain_type TEXT)
AS
$$
BEGIN
  RETURN QUERY
  SELECT
    aas.amino_acid_sequence,
	aas.chain_type
  FROM
    ab_data.amino_acid_sequences aas
  WHERE
    amino_acid_sequence_id IN(
	  SELECT
		get_aa_seq_ids_for_ab_name
	  FROM
		user_defined_crud_functions.get_aa_seq_ids_for_ab_name(p_common_identifer)
	);
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.is_ab_common_identifier_present(p_common_identifier TEXT)
RETURNS BOOLEAN
AS
$$
DECLARE
  l_common_identifier TEXT := UPPER(TRIM(p_common_identifier));
  l_rowcount INTEGER := 0;
BEGIN
  SELECT 
    COUNT(common_identifier) INTO l_rowcount 
  FROM 
    ab_data.antibody_information
  WHERE
    common_identifier = l_common_identifier;
  IF l_rowcount >0 THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;
-- SELECT is_ab_common_identifier_present FROM user_defined_crud_functions.is_ab_common_identifier_present('OBILTOXAXIMAB');

CREATE OR REPLACE FUNCTION user_defined_crud_functions.remove_antibody_record(p_common_identifier TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_common_identifier TEXT := UPPER(TRIM(p_common_identifier));
  l_is_ab_common_identifier_present BOOLEAN := user_defined_crud_functions.is_ab_common_identifier_present(l_common_identifier);
BEGIN
  IF NOT l_is_ab_common_identifier_present THEN
    RETURN FORMAT('The antibody identifier %s was not found!', l_common_identifier);
  END IF;
  DELETE
  FROM
    ab_data.amino_acid_sequences
  WHERE
    amino_acid_sequence_id IN(SELECT 
							    get_aa_seq_ids_for_ab_name 
							  FROM 
							    user_defined_crud_functions.get_aa_seq_ids_for_ab_name(l_common_identifier));
  DELETE FROM ab_data.antibody_information WHERE common_identifier = l_common_identifier;
  
  RETURN FORMAT('Antibody information and sequences for identifier %s were removed!', l_common_identifier);
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;
-- SELECT remove_antibody_record FROM user_defined_crud_functions.remove_antibody_record('IDARUCIZUMAB');

CREATE OR REPLACE FUNCTION user_defined_crud_functions.add_antibody_document_record(p_common_identifier TEXT,
																				   p_file_checksum TEXT,
																				   p_document_name TEXT,
																			       p_document_description TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_retval TEXT;
BEGIN
  INSERT INTO ab_data.antibody_documents(file_checksum, document_name, document_description)
	VALUES(p_file_checksum, p_document_name, p_document_description);
  INSERT INTO ab_data.documents_to_antibodies(common_identifier, file_checksum)
	VALUES(p_common_identifier, p_file_checksum);
  l_retval := CONCAT(l_retval, FORMAT('Successful uploads to "antibody_documents" and "documents_to_antibodies" "%s", document name "%s', p_common_identifier, p_document_name));
  INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);

  RETURN l_retval;

EXCEPTION
  WHEN UNIQUE_VIOLATION THEN  
    l_retval := CONCAT(l_retval, FORMAT('Duplicate entry for antibody "%s" and document name "%s".', p_common_identifier, p_document_name));
    INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
    RETURN l_retval;
  
  WHEN OTHERS THEN
     l_retval := FORMAT('ERROR: %s', SQLERRM);
    INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
    RETURN l_retval;
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.load_antibody_document(p_ab_common_identifier TEXT,
																			  p_file_checksum TEXT,
																			  p_document_name TEXT,
																			  p_document_description TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_retval TEXT;
  l_ab_common_identifier TEXT = TRIM(UPPER(p_ab_common_identifier));
BEGIN
  INSERT INTO ab_data.antibody_documents(file_checksum, document_name, document_description)
    VALUES(p_file_checksum, p_document_name, p_document_description);
  INSERT INTO ab_data.documents_to_antibodies(common_identifier, file_checksum) 
    VALUES(l_ab_common_identifier, p_file_checksum);
  l_retval := FORMAT('Successful upload for document "%s", antibody "%s".', p_document_name, l_ab_common_identifier);
  INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
  RETURN l_retval;

EXCEPTION
  WHEN OTHERS THEN
    l_retval := FORMAT('ERROR: %s', SQLERRM);
    INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
    RETURN l_retval;
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_uploaded_filenames()
RETURNS TABLE(abname_filename TEXT)
AS
$$
BEGIN
  RETURN QUERY
  SELECT
    ad.document_name
  FROM
    ab_data.antibody_documents ad
    JOIN
      ab_data.documents_to_antibodies dta
	  ON
	    ad.file_checksum = dta.file_checksum
  ORDER BY 1;
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.add_note_to_antibody(p_ab_common_identifier TEXT, p_antibody_note_text TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_antibody_note_id INTEGER;
  l_retval TEXT := 'Note ID "%s"  created for antibody "%s".';
BEGIN
  INSERT INTO ab_data.antibody_notes(note_text) 
  	VALUES(p_antibody_note_text) RETURNING antibody_note_id INTO l_antibody_note_id;
  INSERT INTO ab_data.antibody_notes_to_information(common_identifier, antibody_note_id)
  	VALUES(p_ab_common_identifier, l_antibody_note_id);
  l_retval := FORMAT(l_retval, l_antibody_note_id, p_ab_common_identifier);
  INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
  RETURN l_retval;

EXCEPTION
  WHEN OTHERS THEN
    l_retval := FORMAT('ERROR: %s', SQLERRM);
    INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
    RETURN l_retval;
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.load_aa_sequence_and_ab_join(p_ab_common_identifier TEXT,
																				    p_aa_sequence TEXT,
																				    p_chain_type TEXT,
																				    p_sequence_name TEXT DEFAULT NULL)
RETURNS TEXT
AS
$$
DECLARE
  l_ab_common_identifier TEXT := TRIM(UPPER(p_ab_common_identifier));
  l_aa_sequence TEXT :=  user_defined_crud_functions.get_cleaned_amino_acid_sequence(p_aa_sequence);
  l_sequence_hash_id TEXT := user_defined_crud_functions.get_sequence_hash_id(p_aa_sequence);
  l_sequence_name TEXT := COALESCE(p_sequence_name, CONCAT(p_ab_common_identifier, '_', p_chain_type));
  l_retval TEXT := 'load_aa_sequence_and_ab_join: Antibody name: "%s", sequence hash ID: "%s" inserted!';
BEGIN
  INSERT INTO ab_data.amino_acid_sequences(amino_acid_sequence_id, amino_acid_sequence, chain_type, sequence_name)
    VALUES(l_sequence_hash_id, l_aa_sequence, p_chain_type, l_sequence_name);
  INSERT INTO ab_data.sequences_to_information(common_identifier, amino_acid_sequence_id) 
    VALUES(l_ab_common_identifier, l_sequence_hash_id);
  l_retval := FORMAT(l_retval, l_ab_common_identifier, l_sequence_hash_id);
  INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
  RETURN l_retval;

EXCEPTION
  WHEN OTHERS THEN
    l_retval := FORMAT('ERROR: %s', SQLERRM);
    INSERT INTO audit_logs.data_load_logs(load_outcome) VALUES(l_retval);
  
    RETURN l_retval;
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_sequence_hash_ids(p_aa_sequences TEXT[])
RETURNS TEXT[]
AS
$$
DECLARE
  l_sequence_hash_ids TEXT[];
  l_counter INTEGER := 1;
  l_element TEXT;
  l_sequence_hash_id TEXT;
BEGIN
  FOREACH l_element IN ARRAY p_aa_sequences
  LOOP
    l_sequence_hash_id := user_defined_crud_functions.get_sequence_hash_id(l_element);
	l_sequence_hash_ids[l_counter] := l_sequence_hash_id;
	l_counter := l_counter + 1;
  END LOOP;
  
  RETURN l_sequence_hash_ids;
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

-- Functions for client output
CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_ab_data_for_aa_seq(p_search_aa_seq TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_sequence_hash_id TEXT := user_defined_crud_functions.get_sequence_hash_id(p_search_aa_seq);
  l_ab_common_identifiers TEXT[];
  l_data_for_ab JSONB;
BEGIN
  SELECT 
    ARRAY_AGG(common_identifier) INTO l_ab_common_identifiers 
  FROM 
    ab_data.sequences_to_information
  WHERE
    amino_acid_sequence_id = l_sequence_hash_id;
  SELECT
    ROW_TO_JSON(sq) INTO l_data_for_ab
  FROM
    (
	  SELECT
		common_identifier,
		antibody_type,
		target_gene_name,
		antibody_source,
		created_by ab_created_by,
		date_added ab_date_added,
		last_modified_date ab_last_modified_date,
		modified_by ab_modified_by
	  FROM
		ab_data.antibody_information
	  WHERE
		common_identifier IN
		(
			SELECT 
			  UNNEST(l_ab_common_identifiers))
	) sq;
	
	RETURN l_data_for_ab;
	
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_seq_data_for_aa_seq(p_search_aa_seq TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_search_aa_seq_hash_id TEXT := user_defined_crud_functions.get_sequence_hash_id(p_search_aa_seq);
  l_amino_acid_sequence_data JSONB[];
BEGIN
  SELECT
    ARRAY_AGG(ROW_TO_JSON(sq)::JSONB) INTO l_amino_acid_sequence_data
  FROM
    (SELECT
	   'Sequence Found'::TEXT exact_match_result,
	   amino_acid_sequence_id,
       chain_type,
       sequence_name,
       created_by seq_created_by,
       date_added seq_date_added,
       last_modified_date seq_last_modified_date,
       modified_by seq_modified_by
     FROM
       ab_data.amino_acid_sequences
     WHERE
       amino_acid_sequence_id = l_search_aa_seq_hash_id) sq;
	   
  RETURN COALESCE(l_amino_acid_sequence_data[1], '{"exact_match_result": "Sequence not found"}'::JSONB);
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_all_data_for_aa_seq(p_search_aa_seq TEXT)
RETURNS TABLE(attribute_name TEXT, attribute_value TEXT)
AS
$$
BEGIN
RETURN QUERY
  SELECT 
    key attribute_name, 
    value attribute_value 
  FROM 
    JSONB_EACH_TEXT(user_defined_crud_functions.get_seq_data_for_aa_seq(p_search_aa_seq))
  UNION
  SELECT 
    key, 
    value 
  FROM 
    JSONB_EACH_TEXT(user_defined_crud_functions.get_ab_data_for_aa_seq(p_search_aa_seq));
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_ab_common_identifier_for_given_name(p_given_name TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_given_name TEXT := UPPER(TRIM(p_given_name));
  l_is_given_name_common_identifier BOOLEAN;
  l_common_identifier TEXT;
BEGIN
  SELECT 
    EXISTS(SELECT * FROM ab_data.antibody_information WHERE common_identifier = l_given_name) 
    INTO l_is_given_name_common_identifier;
  IF l_is_given_name_common_identifier THEN
    RETURN l_given_name;
  END IF;
  SELECT
    common_identifier INTO l_common_identifier
  FROM
    ab_data.antibody_names_lookup
  WHERE
    UPPER(alternative_name) = l_given_name;
	
  RETURN COALESCE(l_common_identifier, 'Not found');
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_ab_data_for_given_ab_name(p_given_name TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_common_identifier TEXT := user_defined_crud_functions.get_ab_common_identifier_for_given_name(p_given_name);
  l_ab_data_for_given_name JSONB;
BEGIN
  SELECT
    ROW_TO_JSON(sq) INTO l_ab_data_for_given_name
  FROM
    (
	  SELECT
		common_identifier,
		antibody_type,
		target_gene_name,
		antibody_source,
		created_by ab_created_by,
		date_added ab_date_added,
		last_modified_date ab_last_modified_date,
		modified_by ab_modified_by
	  FROM
		ab_data.antibody_information
	  WHERE
		common_identifier = l_common_identifier
	) sq;
	
	RETURN l_ab_data_for_given_name;
	
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_seq_data_for_given_ab_name(p_given_name TEXT)
RETURNS JSONB[]
AS
$$
DECLARE
  l_ab_common_identifier TEXT := user_defined_crud_functions.get_ab_common_identifier_for_given_name(p_given_name);
  l_amino_acid_sequence_ids TEXT[];
  l_amino_acid_sequence_data JSONB[];
BEGIN
  SELECT
    ARRAY_AGG(sti.amino_acid_sequence_id) INTO l_amino_acid_sequence_ids
  FROM
    ab_data.sequences_to_information sti
  WHERE
    sti.common_identifier = l_ab_common_identifier;
  SELECT 
    ARRAY_AGG(ROW_TO_JSON(sq)) INTO l_amino_acid_sequence_data
  FROM
    (SELECT
	  aas.amino_acid_sequence_id,
	  aas.amino_acid_sequence,
      aas.chain_type,
      aas.sequence_name,
      aas.created_by seq_created_by,
      aas.date_added seq_date_added,
      aas.last_modified_date seq_last_modified_date,
      aas.modified_by seq_modified_by
    FROM
      ab_data.amino_acid_sequences aas
    WHERE
      aas.amino_acid_sequence_id IN (
	    SELECT
		  UNNEST(l_amino_acid_sequence_ids)
	   )
  ) sq;
  
  RETURN l_amino_acid_sequence_data;
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_all_data_for_given_ab_name(p_given_name TEXT)
RETURNS TABLE(attribute_name TEXT, attribute_value TEXT)
AS
$$
BEGIN
RETURN QUERY
  SELECT
    (JSONB_EACH_TEXT(UNNEST(user_defined_crud_functions.get_seq_data_for_given_ab_name(p_given_name)))).key attribute_name,
    (JSONB_EACH_TEXT(UNNEST(user_defined_crud_functions.get_seq_data_for_given_ab_name(p_given_name)))).value attribute_value
  UNION
  SELECT 
    key, 
    value 
  FROM 
    JSONB_EACH_TEXT(user_defined_crud_functions.get_ab_data_for_given_ab_name(p_given_name));
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION user_defined_crud_functions.get_matched_sequences_for_subseq(p_subseq TEXT)
RETURNS TABLE(sequence_name TEXT, chain_type TEXT, amino_acid_sequence TEXT, common_identifier TEXT, antibody_type TEXT)
AS
$$
DECLARE
  l_subseq TEXT := user_defined_crud_functions.get_cleaned_amino_acid_sequence(p_subseq);
BEGIN
  RETURN QUERY
  SELECT
    aas.sequence_name,
    aas.chain_type,
    aas.amino_acid_sequence,
    ai.common_identifier,
    ai.antibody_type
  FROM
    ab_data.amino_acid_sequences aas
    LEFT OUTER JOIN
      ab_data.sequences_to_information sti
	  ON
	    aas.amino_acid_sequence_id = sti.amino_acid_sequence_id
    JOIN
      ab_data.antibody_information ai
	  ON
	    sti.common_identifier = ai.common_identifier
  WHERE
    aas.amino_acid_sequence ~ l_subseq;
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;


-- Functions written for Excel VBA client
CREATE OR REPLACE FUNCTION user_defined_crud_functions.load_excel_batch_row(p_rows_values TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_rows_values TEXT[] := STRING_TO_ARRAY(p_rows_values, E'\n');
  l_single_row_values TEXT[];
  l_common_identifier TEXT;
  l_antibody_type TEXT;
  l_target_gene_name TEXT;
  l_antibody_source TEXT;
  l_antibody_url TEXT;
  l_antibody_note TEXT;
  l_h_chain_sequence TEXT;
  l_l_chain_sequence TEXT;
  l_current_row TEXT;
  l_load_result_hchain TEXT;
  l_load_result_lchain TEXT;
  l_load_result_abbnote TEXT;
  l_load_result_row TEXT;
  l_load_result_rows TEXT[];
  l_index INTEGER := 1;
BEGIN
  FOREACH l_current_row IN ARRAY l_rows_values
  LOOP
    l_single_row_values := STRING_TO_ARRAY(l_current_row, E'\t');
	l_common_identifier := UPPER(TRIM(l_single_row_values[1]));
	l_antibody_type := TRIM(l_single_row_values[2]);
	l_target_gene_name := TRIM(l_single_row_values[3]);
    l_antibody_source := TRIM(l_single_row_values[4]);
    l_antibody_url := TRIM(l_single_row_values[5]);
    l_antibody_note := TRIM(l_single_row_values[6]);
    l_h_chain_sequence := l_single_row_values[7];
    l_l_chain_sequence := l_single_row_values[8];
	SELECT 
	  create_new_antibody_sequence_entry INTO l_load_result_hchain
	FROM  
	  user_defined_crud_functions.create_new_antibody_sequence_entry(l_common_identifier,
																	l_antibody_type,
																	l_target_gene_name,
																	l_antibody_source,
																	l_antibody_url,
																	l_h_chain_sequence,
																	'H'::TEXT);
    SELECT 
	  create_new_antibody_sequence_entry INTO l_load_result_lchain
	FROM  
	  user_defined_crud_functions.create_new_antibody_sequence_entry(l_common_identifier,
																	l_antibody_type,
																	l_target_gene_name,
																	l_antibody_source,
																	l_antibody_url,
																	l_l_chain_sequence,
																	'L'::TEXT);
    IF LENGTH(l_antibody_note)	> 0 THEN															
      SELECT
	    add_note_to_antibody INTO l_load_result_abbnote
      FROM
	    user_defined_crud_functions.add_note_to_antibody(l_common_identifier, l_antibody_note);
	END IF;
    l_load_result_row := ARRAY_TO_STRING(ARRAY[l_load_result_hchain, l_load_result_lchain, l_load_result_abbnote], E'\t');
	l_load_result_rows[l_index] := l_load_result_row;
	l_index := l_index + 1;
  END LOOP;

  RETURN ARRAY_TO_STRING(l_load_result_rows, E'\n');
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;

-- Reset permissions on re-created schema and its objects
GRANT USAGE ON SCHEMA user_defined_crud_functions TO mabmindergroup;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA user_defined_crud_functions TO mabmindergroup;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ab_data TO mabmindergroup;



