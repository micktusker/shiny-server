CREATE OR REPLACE FUNCTION antibodies.add_new_antibody_sequence(p_antibody_name TEXT,
                                                                p_aa_sequence TEXT,
                                                                p_extra_metadata TEXT DEFAULT '{}')
RETURNS JSONB
AS
$$
  DECLARE
l_aa_sequence TEXT := REGEXP_REPLACE(UPPER(p_aa_sequence), '\s', '');
l_aa_sequence_id TEXT := MD5(l_aa_sequence);
l_antibody_name TEXT := TRIM(UPPER(p_antibody_name));
l_aa_sequence_metadata_id TEXT := MD5(CONCAT(l_aa_sequence_id, l_antibody_name));
l_extra_metadata JSONB := CAST(p_extra_metadata AS JSONB);
l_retval TEXT := '{"New Antibody Entry Created": "%s", ' || 
  '"New Meta Data Entry Created": "%s", ' ||
  '"Load Date": "%s", ' ||
  '"Account": "%s", ' ||
  '"Sequence ID": "%s", ' ||
  '"Meta Data ID": "%s"}';
l_positive_outcome TEXT := 'YES';
l_negative_outcome TEXT := 'NO';
l_err_retval TEXT := '{"ERROR": "%s", ' ||
  '"Load Date": "%s", ' ||
  '"Account": "%s", ' ||
  '"Antibody Name": "%s", ' ||
  '"Antibody Sequence": "%s"}';
l_sqlerrm TEXT;
BEGIN
l_retval := FORMAT(l_retval, '%s', '%s', CURRENT_TIMESTAMP, '%s', '%s', '%s');
l_retval := FORMAT(l_retval, '%s', '%s', CURRENT_USER, '%s', '%s');
l_retval := FORMAT(l_retval, '%s', '%s', l_aa_sequence_id, '%s');
l_retval := FORMAT(l_retval, '%s', '%s', l_aa_sequence_metadata_id);
BEGIN
INSERT INTO antibodies.aa_sequences(aa_sequence_id, aa_sequence)
VALUES(l_aa_sequence_id, l_aa_sequence);
l_retval := FORMAT(l_retval, l_positive_outcome, '%s');
EXCEPTION
WHEN UNIQUE_VIOLATION THEN
l_retval := FORMAT(l_retval, l_negative_outcome, '%s');
END;
BEGIN
INSERT INTO antibodies.aa_sequence_metadata(aa_sequence_metadata_id, antibody_name, aa_sequence_id, extra_metadata)
VALUES(l_aa_sequence_metadata_id, l_antibody_name, l_aa_sequence_id, l_extra_metadata);
l_retval := FORMAT(l_retval, l_positive_outcome);
EXCEPTION
WHEN UNIQUE_VIOLATION THEN
l_retval := FORMAT(l_retval, l_negative_outcome);
END;

RETURN l_retval::JSONB;

EXCEPTION
WHEN OTHERS THEN
l_sqlerrm := SQLERRM;
l_sqlerrm := REPLACE(l_sqlerrm, '"', '|');
l_err_retval := (FORMAT(l_err_retval, 
                        l_sqlerrm, 
                        CURRENT_TIMESTAMP,
                        CURRENT_USER,
                        p_antibody_name,
                        p_aa_sequence))::JSONB;

RETURN l_err_retval::JSONB;

END;
$$
  LANGUAGE plpgsql
SECURITY DEFINER;

SELECT * FROM antibodies.add_new_antibody_sequence('test ab 1', 'EVQLLESGGGLVQPGGSLRLSCAASGFTFSSYGMSWVRQAPGKGLELVSTINGYGDTTYYPDSVKGRFTISRDNSKNTLYLQMNSLRAEDTAVYYCARDRDYGNSYYYALDYWGQGTLVTVSS');
























