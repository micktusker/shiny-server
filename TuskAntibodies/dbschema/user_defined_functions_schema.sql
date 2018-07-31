DROP SCHEMA IF EXISTS user_defined_functions CASCADE;
CREATE SCHEMA user_defined_functions;
COMMENT ON SCHEMA user_defined_functions IS 'Contains all general functions written specifically for general Tusk antibody operations.';

CREATE OR REPLACE FUNCTION user_defined_functions.get_cleaned_amino_acid_sequence(p_amino_acid_sequence TEXT, p_extra_allowable_chars TEXT DEFAULT NULL)
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

CREATE OR REPLACE FUNCTION user_defined_functions.get_sequence_hash_id(p_ab_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_sequence_hash_id TEXT;
  l_ab_sequence TEXT;
BEGIN
  l_ab_sequence := user_defined_functions.get_cleaned_amino_acid_sequence(p_ab_sequence);
  
  RETURN MD5(l_ab_sequence);
  
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION user_defined_functions.is_valid_amino_acid_sequence(p_amino_acid_sequence TEXT, p_extra_allowable_chars TEXT DEFAULT NULL)
RETURNS BOOLEAN
AS
$$
DECLARE
  l_amino_acid_sequence TEXT := UPPER(REGEXP_REPLACE(p_amino_acid_sequence, '\s', '', 'g'));
  l_amino_acids TEXT := CONCAT('ACDEFGHIKLMNPQRSTVWY', p_extra_allowable_chars);
  l_regex TEXT := CONCAT('^[', l_amino_acids, ']+$');
BEGIN
  IF l_amino_acid_sequence ~ l_regex THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
  
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION user_defined_functions.get_antibody_name_for_given_name(p_given_name TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_given_name TEXT := UPPER(TRIM(p_given_name));
  l_is_given_name_antibody_name BOOLEAN;
  l_antibody_name TEXT;
BEGIN
  SELECT 
    EXISTS(SELECT * FROM ab_data.antibodies WHERE antibody_name = l_given_name) 
    INTO l_is_given_name_antibody_name;
  IF l_is_given_name_antibody_name THEN
    RETURN l_given_name;
  END IF;
  SELECT
    antibody_name INTO l_antibody_name
  FROM
    ab_data.antibody_names_lookup
  WHERE
    UPPER(alternative_name) = l_given_name;
	
  RETURN COALESCE(l_antibody_name, 'Not found');
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;
-- DROP FUNCTION IF EXISTS user_defined_functions.get_antibody_name_for_given_name(TEXT);
SELECT * FROM user_defined_functions.get_antibody_name_for_given_name('Daclizumab');

/*
Functions used by R Shiny to return information

*/

-- Return a JSONB value of sequences for a given antibody name.
-- The given name can be any name defined in |antibody_names_lookup|. This function resolves the name to the
-- one used in the |antibodies| table. This function was written to be called by |get_all_data_for_given_ab_name|.
CREATE OR REPLACE FUNCTION user_defined_functions.get_seq_data_for_given_ab_name(p_given_name TEXT)
RETURNS JSONB[]
AS
$$
DECLARE
  l_antibody_name TEXT := user_defined_functions.get_antibody_name_for_given_name(p_given_name);
  l_sequence_names TEXT[];
  l_amino_acid_sequence_data JSONB[];
BEGIN
  SELECT
    ARRAY_AGG(a2cs.sequence_name) INTO l_sequence_names
  FROM
    ab_data.antibody_to_chain_sequence a2cs
  WHERE
    a2cs.antibody_name = l_antibody_name;
  SELECT 
    ARRAY_AGG(ROW_TO_JSON(sq)) INTO l_amino_acid_sequence_data
  FROM
    (SELECT
	  cs.sequence_name,
      cs.chain_type,
      cs.created_by seq_created_by,
      cs.date_added seq_date_added,
	  cs.ig_subclass,
	  cs.target_gene_name,
      cs.last_modified_date seq_last_modified_date,
      cs.modified_by seq_modified_by
    FROM
      ab_data.chain_sequences cs
    WHERE
      cs.sequence_name IN (
	    SELECT
		  UNNEST(l_sequence_names)
	   )
  ) sq;
  
  RETURN l_amino_acid_sequence_data;
  
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;
SELECT * FROM user_defined_functions.get_seq_data_for_given_ab_name('TSK014001');

-- Return a JSONB value of antibody details for a given antibody name.
-- The given name can be any name defined in |antibody_names_lookup|. This function resolves the name to the
-- one used in the |antibodies| table. This function was written to be called by |get_all_data_for_given_ab_name|.
CREATE OR REPLACE FUNCTION user_defined_functions.get_ab_data_for_given_ab_name(p_given_name TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_antibody_name TEXT := user_defined_functions.get_antibody_name_for_given_name(p_given_name);
  l_ab_data_for_given_name JSONB;
BEGIN
  SELECT
    ROW_TO_JSON(sq) INTO l_ab_data_for_given_name
  FROM
    (
	  SELECT
		antibody_name,
		antibody_source,
		created_by ab_created_by,
		date_added ab_date_added,
		last_modified_date ab_last_modified_date,
		modified_by ab_modified_by
	  FROM
		ab_data.antibodies
	  WHERE
		antibody_name = l_antibody_name
	) sq;
	
	RETURN l_ab_data_for_given_name;
	
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;
SELECT * FROM user_defined_functions.get_ab_data_for_given_ab_name('TSK014001');

-- Return a table of antibody and sequence details for a given antibody identifier. Details will be returned
-- for any antibody identifier that is mapped to an antibody name by the table |antibody_names_lookup| to
-- the name used in table |antibodies|.
CREATE OR REPLACE FUNCTION user_defined_functions.get_all_data_for_given_ab_name(p_given_name TEXT)
RETURNS TABLE(attribute_name TEXT, attribute_value TEXT)
AS
$$
BEGIN
RETURN QUERY
  SELECT
    (JSONB_EACH_TEXT(UNNEST(user_defined_functions.get_seq_data_for_given_ab_name(p_given_name)))).key attribute_name,
    (JSONB_EACH_TEXT(UNNEST(user_defined_functions.get_seq_data_for_given_ab_name(p_given_name)))).value attribute_value
  UNION
  SELECT 
    key, 
    value 
  FROM 
    JSONB_EACH_TEXT(user_defined_functions.get_ab_data_for_given_ab_name(p_given_name))
  ORDER BY 1;
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;
SELECT * FROM user_defined_functions.get_all_data_for_given_ab_name('TSK014001');

-- Return a table of 0 or more rows with sequence and antibody summary information for a given sequence.
-- This function performs an exact match and returns 0 rows if the antibody sequence is not found.
-- If the given sequence is duplicated in the database (same sequence attached to different sequence names)
-- or the same sequence is shared by different antibodies, then multiple rows will be returned.
CREATE OR REPLACE FUNCTION user_defined_functions.get_all_data_for_aa_seq(p_search_aa_seq TEXT)
RETURNS TABLE(antibody_name TEXT, antibody_source TEXT, antibody_description TEXT, sequence_name TEXT, chain_type TEXT, ig_subclass TEXT, target_gene_name TEXT)
AS
$$
DECLARE
  l_sequence_hash_id TEXT := user_defined_functions.get_sequence_hash_id(p_search_aa_seq);
BEGIN
  RETURN QUERY
  SELECT
    ab.antibody_name,
    ab.antibody_source,
    ab.antibody_description,
    sq.sequence_name,
    sq.chain_type,
    sq.ig_subclass,
    sq.target_gene_name
  FROM
    (SELECT
       cs.sequence_name,
       cs.chain_type,
       cs.ig_subclass,
       cs.target_gene_name
     FROM
       ab_data.chain_sequences cs
     WHERE
       sequence_hash_id = l_sequence_hash_id) sq
       LEFT OUTER JOIN
         ab_data.antibody_to_chain_sequence a2cs
	     ON
	       sq.sequence_name = a2cs.sequence_name
       JOIN
         ab_data.antibodies ab
	     ON
	       a2cs.antibody_name = ab.antibody_name;
END;
$$
LANGUAGE plpgsql
SECURITY INVOKER;
SELECT * FROM user_defined_functions.get_all_data_for_aa_seq('QVQLQESGPGLVKPSQTLSLTCTVSGGSISSGGYYWSWIRQHPGKGLEWIGYIYYSGSTYYNPSLKSRVTISVDTSKNQFSLKLSSVTAADTAVYYCARAKSELVLPYYYYMDVWGKGTTVTVSS');




-- Reset permissions on re-created schema and its objects
GRANT USAGE ON SCHEMA user_defined_functions TO mabmindergroup;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA user_defined_functions TO mabmindergroup;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ab_data TO mabmindergroup;

