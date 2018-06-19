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
SELECT get_cleaned_amino_acid_sequence FROM user_defined_crud_functions.get_cleaned_amino_acid_sequence('PQVTLWQRPI VTIKIGGQLK EALLDTGADD TVLEEMSLPG KWKPKMIGGIX', 'X');



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
																				p_chain_type TEXT)
RETURNS BOOLEAN
AS
$$
DECLARE
  l_new_record_created BOOLEAN;
BEGIN
  INSERT INTO ab_data.amino_acid_sequences(amino_acid_sequence_id, amino_acid_sequence, chain_type)
    VALUES(p_amino_acid_sequence_hash_id, p_amino_acid_sequence, p_chain_type);
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
BEGIN
  l_new_information_record_created := user_defined_crud_functions.load_antibody_information(l_common_identifier, p_antibody_type, p_gene_name, p_antibody_source, p_source_database_url);
  l_new_sequence_record_created := user_defined_crud_functions.load_amino_acid_sequence(l_antibody_sequence_hash_id, l_antibody_sequence, p_chain_type);
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
SELECT is_ab_common_identifier_present FROM user_defined_crud_functions.is_ab_common_identifier_present('OBILTOXAXIMAB');

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
SELECT remove_antibody_record FROM user_defined_crud_functions.remove_antibody_record('IDARUCIZUMAB');

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



-- Reset permissions on re-created schema and its objects
GRANT USAGE ON SCHEMA user_defined_crud_functions TO mabmindergroup;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA user_defined_crud_functions TO mabmindergroup;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ab_data TO mabmindergroup;



