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

-- Loading antibodies
CREATE OR REPLACE FUNCTION antibodies.load_information(p_common_identifier TEXT,
													   p_antibody_type TEXT,
													   p_antibody_source TEXT,
													   p_source_database_id TEXT,
													   p_source_database_url TEXT)
RETURNS BOOLEAN
AS
$$
DECLARE
 l_new_record_created BOOLEAN;
BEGIN
  INSERT INTO antibodies.information(common_identifier, antibody_type, antibody_source, source_database_id, source_database_url)
    VALUES(p_common_identifier, p_antibody_type, p_antibody_source, p_source_database_id, p_source_database_url);
  l_new_record_created := TRUE;
  
  RETURN l_new_record_created;
  
EXCEPTION
  WHEN UNIQUE_VIOLATION THEN
    l_new_record_created := FALSE;
	
	RETURN l_new_record_created;
	
END;
$$
LANGUAGE plpgsql
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION antibodies.load_amino_acid_sequence(p_amino_acid_sequence_hash_id TEXT, p_amino_acid_sequence TEXT, p_chain_type TEXT)
RETURNS BOOLEAN
AS
$$
DECLARE
  l_new_record_created BOOLEAN;
BEGIN
  INSERT INTO antibodies.amino_acid_sequences(amino_acid_sequence_id, amino_acid_sequence, chain_type)
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
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION antibodies.create_new_antibody_sequence_entry(p_common_identifier TEXT,
																		 p_antibody_type TEXT,
													                     p_antibody_source TEXT,
													                     p_source_database_id TEXT,
													                     p_source_database_url TEXT,
																		 p_antibody_sequence TEXT,
																		 p_chain_type TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_common_identifier TEXT := TRIM(UPPER(p_common_identifier));
  l_antibody_sequence TEXT := antibodies.get_cleaned_amino_acid_sequence(p_antibody_sequence);
  l_antibody_sequence_hash_id TEXT := antibodies.get_sequence_hash_id(p_antibody_sequence);
  l_retval TEXT := 'Successful upload of record for antibody identifier "%s" and antibody sequence hash ID "%s". New information row created: "%s". New sequence row created: "%s"';
  l_new_information_record_created BOOLEAN;
  l_new_sequence_record_created BOOLEAN;
BEGIN
  l_new_information_record_created := antibodies.load_information(l_common_identifier, p_antibody_type, p_antibody_source, p_source_database_id, p_source_database_url);
  l_new_sequence_record_created := antibodies.load_amino_acid_sequence(l_antibody_sequence_hash_id, l_antibody_sequence, p_chain_type);
  INSERT INTO antibodies.information_amino_acid_sequences(common_identifier, amino_acid_sequence_id)
    VALUES(l_common_identifier, l_antibody_sequence_hash_id);
  l_retval := FORMAT(l_retval, l_common_identifier, l_antibody_sequence_hash_id, l_new_information_record_created, l_new_sequence_record_created);
  
  RETURN l_retval;

EXCEPTION
  WHEN UNIQUE_VIOLATION THEN
    l_retval := FORMAT('Duplicate entry for antibody identifier "%s" and sequence hash ID "%s".', l_common_identifier, l_antibody_sequence_hash_id);
	
	RETURN l_retval;
	
  WHEN OTHERS THEN
    l_retval := FORMAT('ERROR: %s', SQLERRM);

	RETURN l_retval;
	
END;
$$
LANGUAGE plpgsql
SECURITY DEFINER;


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





-- CDR determination
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



-- Functions for IMGT and FASTA
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





















