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

CREATE OR REPLACE FUNCTION antibodies.get_fasta_sequences_for_imgt_ids(p_imgt_ids TEXT[])
RETURNS TEXT[]
AS
$$
DECLARE
  l_fasta_seqs TEXT[];
  l_counter INTEGER := 1;
  l_response TEXT;
  imgt_id TEXT;
BEGIN
  FOREACH imgt_id IN ARRAY p_imgt_ids
  LOOP
    BEGIN
	    l_response := bix_udfs.get_fasta_seq_as_aa_for_gene_synonym(imgt_id);
	    l_response := CONCAT(imgt_id, E'\t', l_response);
	    l_fasta_seqs[l_counter] := l_response;
	    l_counter := l_counter + 1;
	  EXCEPTION
	    WHEN OTHERS THEN
	      l_response := CONCAT(imgt_id, E'\t', 'ERROR');
	      l_fasta_seqs[l_counter] := l_response;
	      l_counter := l_counter + 1;
	  END;
  END LOOP;
  
  RETURN l_fasta_seqs;
  
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;
SELECT antibodies.get_fasta_sequences_for_imgt_ids(ARRAY['IGHV4-34', 'IGHV3-21', 'IGHV1-2']);

CREATE OR REPLACE FUNCTION antibodies.get_fasta_sequencesimgt_table()
RETURNS TABLE(imgt_gene_name TEXT, fasta_sequence TEXT)
AS
$$
DECLARE
  l_imgt_gene_names TEXT[];
BEGIN
  SELECT 
    ARRAY_AGG(lu.imgt_gene_name) INTO l_imgt_gene_names 
  FROM
    antibodies.germline_adimab_imgt_lu lu;
  RETURN QUERY
  SELECT 
    (STRING_TO_ARRAY(UNNEST(get_fasta_sequences_for_imgt_ids), E'\t'))[1] imgt_gene_name,
	(STRING_TO_ARRAY(UNNEST(get_fasta_sequences_for_imgt_ids), E'\t'))[2] fasta_sequence
  FROM
    antibodies.get_fasta_sequences_for_imgt_ids(l_imgt_gene_names);
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;
CREATE TABLE antibodies.imgt_gene_fasta_sequences AS SELECT * FROM antibodies.get_fasta_sequencesimgt_table();






















