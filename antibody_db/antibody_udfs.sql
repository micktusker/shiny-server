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

CREATE OR REPLACE FUNCTION antibodies.get_sequence_hash_id(p_ab_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_sequence_hash_id TEXT;
  l_ab_sequence TEXT;
BEGIN
  l_ab_sequence := antibodies.get_cleaned_amino_acid_sequence(p_ab_sequence);
  
  RETURN MD5(l_ab_sequence);
  
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;


CREATE OR REPLACE FUNCTION antibodies.add_mab_sequence(p_mab_identifier TEXT,
											p_source_database_id TEXT,
											p_source_database_url TEXT,
											p_antibody_type TEXT,
											p_heavy_chain_sequence TEXT,
											p_light_chain_sequence TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_retval TEXT := '{"load_outcome": "%s", "error_message": "%s"}';
  l_sql_err_msg TEXT := 'NONE';
  l_mab_full_sequence_has_id TEXT := antibodies.get_sequence_hash_id(CONCAT(p_heavy_chain_sequence, p_light_chain_sequence));
  l_heavy_chain_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_heavy_chain_sequence);
  l_light_chain_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_light_chain_sequence);
BEGIN
  
  INSERT INTO antibodies.mab_sequences(mab_full_sequence_hash_id, 
									   commonly_known_as, 
									   source_database_id, 
									   source_database_url, 
									   antibody_type, 
									   heavy_chain_sequence, 
									   light_chain_sequence)
    VALUES(l_mab_full_sequence_has_id,
		  p_mab_identifier,
		  p_source_database_id,
		  p_source_database_url,
		  p_antibody_type,
		  l_heavy_chain_sequence,
		  l_light_chain_sequence);
  l_retval := FORMAT(l_retval, 'Loaded', l_sql_err_msg);
  
  RETURN l_retval::JSONB;
  
EXCEPTION
   WHEN UNIQUE_VIOLATION THEN
     l_retval := FORMAT(l_retval, 'Not Loaded', 'Ab sequence already in the database!');
	 
	 RETURN l_retval::JSONB;
	 
   WHEN OTHERS THEN
     l_sql_err_msg := SQLERRM;
	   l_sql_err_msg := REPLACE(l_sql_err_msg, '"', '|');
	   l_retval := FORMAT(l_retval, 'Not loaded', l_sql_err_msg);
	 
	 RETURN l_retval;
	 
END;
$$
LANGUAGE plpgsql
SECURITY DEFINER;



-- CDR determination
CREATE OR REPLACE FUNCTION antibodies.get_cleaned_amino_acid_sequence(p_amino_acid_sequence TEXT, p_extra_allowable_chars TEXT DEFAULT NULL)
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
SELECT get_cleaned_amino_acid_sequence FROM antibodies.get_cleaned_amino_acid_sequence('PQVTLWQRPI VTIKIGGQLK EALLDTGADD TVLEEMSLPG KWKPKMIGGIX', 'X');

CREATE OR REPLACE FUNCTION antibodies.get_CDR_VL1_sequence(p_VL_amino_acid_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_regexp TEXT := 'C(\w{10,17})W[YLF][QL]';
  l_VL_amino_acid_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_VL_amino_acid_sequence);
  l_matches TEXT[] := REGEXP_MATCHES(l_VL_amino_acid_sequence, l_regexp);
BEGIN
  RETURN l_matches[1];
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;
SELECT antibodies.get_CDR_VL1_sequence('EIVLTQSPATLSLSPGERATLSCRASQSVSSYLAWYQQKPGQAPRLLIYDASNRATGIPA RFSGSGSGTDFTLTISSLEPEDFAVYYCQQRSNWPPTFGQGTKVEIKRTVAAPSVFIFPP SDEQLKSGTASVVCLLNNFYPREAKVQWKVDNALQSGNSQESVTEQDSKDSTYSLSSTLT LSKADYEKHKVYACEVTHQGLSSPVTKSFNRGEC');

CREATE OR REPLACE FUNCTION antibodies.get_CDR_VL2_sequence(p_VL_amino_acid_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_regexp TEXT := 'C\w{10,17}W[YLF][QL]\w+[IV][YKF](\w{7})';
  l_VL_amino_acid_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_VL_amino_acid_sequence);
  l_matches TEXT[] := REGEXP_MATCHES(l_VL_amino_acid_sequence, l_regexp);
BEGIN
  RETURN l_matches[1];
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;
SELECT antibodies.get_CDR_VL2_sequence('EIVLTQSPATLSLSPGERATLSCRASQSVSSYLAWYQQKPGQAPRLLIYDASNRATGIPA RFSGSGSGTDFTLTISSLEPEDFAVYYCQQRSNWPPTFGQGTKVEIKRTVAAPSVFIFPP SDEQLKSGTASVVCLLNNFYPREAKVQWKVDNALQSGNSQESVTEQDSKDSTYSLSSTLT LSKADYEKHKVYACEVTHQGLSSPVTKSFNRGEC');

CREATE OR REPLACE FUNCTION antibodies.get_CDR_VL3_sequence(p_VL_amino_acid_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_regexp TEXT := 'C\w{10,17}W[YLF][QL]\w+[IV][YKF]\w+C(\w{7,11})FG\w{1}G';
  l_VL_amino_acid_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_VL_amino_acid_sequence);
  l_matches TEXT[] := REGEXP_MATCHES(l_VL_amino_acid_sequence, l_regexp);
BEGIN
  RETURN l_matches[1];
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;
SELECT antibodies.get_CDR_VL3_sequence('EIVLTQSPATLSLSPGERATLSCRASQSVSSYLAWYQQKPGQAPRLLIYDASNRATGIPA RFSGSGSGTDFTLTISSLEPEDFAVYYCQQRSNWPPTFGQGTKVEIKRTVAAPSVFIFPP SDEQLKSGTASVVCLLNNFYPREAKVQWKVDNALQSGNSQESVTEQDSKDSTYSLSSTLT LSKADYEKHKVYACEVTHQGLSSPVTKSFNRGEC');

CREATE OR REPLACE FUNCTION antibodies.get_CDR_VH1_sequence(p_VH_amino_acid_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_regexp TEXT := 'C\w{3}(\w{10,12})W[VIA]';
  l_VH_amino_acid_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_VH_amino_acid_sequence);
  l_matches TEXT[] := REGEXP_MATCHES(l_VH_amino_acid_sequence, l_regexp);
BEGIN
  RETURN l_matches[1];
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;
SELECT antibodies.get_CDR_VH1_sequence('EVQLLESGGGLVQPGGSLRLSCAVSGFTFNSFAMSWVRQAPGKGLEWVSAISGSGGGTYY ADSVKGRFTISRDNSKNTLYLQMNSLRAEDTAVYFCAKDKILWFGEPVFDYWGQGTLVTV SSASTKGPSVFPLAPSSKSTSGGTAALGCLVKDYFPEPVTVSWNSGALTSGVHTFPAVLQ SSGLYSLSSVVTVPSSSLGTQTYICNVNHKPSNTKVDKRVEPKSCDKTHTCPPCPAPELL GGPSVFLFPPKPKDTLMISRTPEVTCVVVDVSHEDPEVKFNWYVDGVEVHNAKTKPREEQ YNSTYRVVSVLTVLHQDWLNGKEYKCKVSNKALPAPIEKTISKAKGQPREPQVYTLPPSR EEMTKNQVSLTCLVKGFYPSDIAVEWESNGQPENNYKTTPPVLDSDGSFFLYSKLTVDKS RWQQGNVFSCSVMHEALHNHYTQKSLSLSPGK');

CREATE OR REPLACE FUNCTION antibodies.get_CDR_VH2_sequence(p_VH_amino_acid_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_regexp TEXT := 'C\w{3}\w{10,12}W[VIA]\w+LE[YWL]\w{2}(\w{16,19})[KR][LIVFTA][TSIA]';
  l_VH_amino_acid_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_VH_amino_acid_sequence);
  l_matches TEXT[] := REGEXP_MATCHES(l_VH_amino_acid_sequence, l_regexp);
BEGIN
  RETURN l_matches[1];
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;
SELECT antibodies.get_CDR_VH2_sequence('EVQLLESGGGLVQPGGSLRLSCAVSGFTFNSFAMSWVRQAPGKGLEWVSAISGSGGGTYY ADSVKGRFTISRDNSKNTLYLQMNSLRAEDTAVYFCAKDKILWFGEPVFDYWGQGTLVTV SSASTKGPSVFPLAPSSKSTSGGTAALGCLVKDYFPEPVTVSWNSGALTSGVHTFPAVLQ SSGLYSLSSVVTVPSSSLGTQTYICNVNHKPSNTKVDKRVEPKSCDKTHTCPPCPAPELL GGPSVFLFPPKPKDTLMISRTPEVTCVVVDVSHEDPEVKFNWYVDGVEVHNAKTKPREEQ YNSTYRVVSVLTVLHQDWLNGKEYKCKVSNKALPAPIEKTISKAKGQPREPQVYTLPPSR EEMTKNQVSLTCLVKGFYPSDIAVEWESNGQPENNYKTTPPVLDSDGSFFLYSKLTVDKS RWQQGNVFSCSVMHEALHNHYTQKSLSLSPGK');
-- Had to add the L to the character class "[YWL]" to get a match with some of our antibodies!!

CREATE OR REPLACE FUNCTION antibodies.get_CDR_VH3_sequence(p_VH_amino_acid_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_regexp TEXT := 'C\w{3}\w{10,12}W[VIA]\w+LE[YWL]\w{2}\w{16,19}[KR][LIVFTA][TSIA]\w+C\w{2}(\w{3,25})WG\w{1}G';
  l_VH_amino_acid_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_VH_amino_acid_sequence);
  l_matches TEXT[] := REGEXP_MATCHES(l_VH_amino_acid_sequence, l_regexp);
BEGIN
  RETURN l_matches[1];
END;
$$
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER;
SELECT antibodies.get_CDR_VH3_sequence('EVQLLESGGGLVQPGGSLRLSCAVSGFTFNSFAMSWVRQAPGKGLEWVSAISGSGGGTYY ADSVKGRFTISRDNSKNTLYLQMNSLRAEDTAVYFCAKDKILWFGEPVFDYWGQGTLVTV SSASTKGPSVFPLAPSSKSTSGGTAALGCLVKDYFPEPVTVSWNSGALTSGVHTFPAVLQ SSGLYSLSSVVTVPSSSLGTQTYICNVNHKPSNTKVDKRVEPKSCDKTHTCPPCPAPELL GGPSVFLFPPKPKDTLMISRTPEVTCVVVDVSHEDPEVKFNWYVDGVEVHNAKTKPREEQ YNSTYRVVSVLTVLHQDWLNGKEYKCKVSNKALPAPIEKTISKAKGQPREPQVYTLPPSR EEMTKNQVSLTCLVKGFYPSDIAVEWESNGQPENNYKTTPPVLDSDGSFFLYSKLTVDKS RWQQGNVFSCSVMHEALHNHYTQKSLSLSPGK');
-- Had to add the L to the character class "[YWL]" to get a match with some of our antibodies!!

























