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
