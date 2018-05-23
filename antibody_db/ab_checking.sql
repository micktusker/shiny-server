-- Record all steps and data sources used to check Absequences in this file.

-- Target table for file uploads prior to extraction and processing
CREATE UNLOGGED TABLE antibodies.transit_tmp(
  data_row TEXT);
COMMENT ON TABLE antibodies.transit_tmp IS $$To be used to transfer local data to database. Data placed here is considered temporary and should only be loaded, processed and deleted as soon as poosible.$$;

-- Load all Ab sequences with associated metadata here
CREATE TABLE antibodies.aa_sequences_check(
  aa_sequences_check_id SERIAL PRIMARY KEY,  
  antibody_hash_id TEXT,
  antibody_sequence TEXT,
  metadata JSONB,
  data_source TEXT,
  gene_target TEXT);
COMMENT ON TABLE antibodies.aa_sequences_check IS
$$
Load all sequences to check into this table and store metadata as key-value pairs in JSONB.
$$;
-- Processing data uploaded using psql command:
-- "#  \COPY antibodies.transit_tmp FROM /Users/michaelmaguire/rtusk/mygithub/shiny-server/antibody_db/seqs2check/cd38_04_and_variants_sequences_to_licence_worddoc.txt  DELIMITER E'\b'"
INSERT INTO antibodies.aa_sequences_check(
	antibody_hash_id, 
	antibody_sequence, 
	metadata, 
	data_source, 
	gene_target)  
SELECT
  MD5(UPPER(TRIM((STRING_TO_ARRAY(data_row, E'\t'))[2]))) antibody_hash_id,
  UPPER(TRIM((STRING_TO_ARRAY(data_row, E'\t'))[2])) antibody_sequence,
  JSONB_OBJECT(ARRAY['tusk_id', 'clone_name', 'adimab_id', 'chain'],
               STRING_TO_ARRAY((STRING_TO_ARRAY(data_row, E'\t'))[1], '_')) metadata,
  'T:\Bioinformatics\AntibodyDB\BG for Michael\For CD38 new Patents\04 and variants sequences to licence'::TEXT data_source,
  'CD38'::TEXT gene_target
FROM
  antibodies.transit_tmp;
-- Create a table to map the gene names used by Adimab for the germline genes to IMGT identifiers.
CREATE TABLE antibodies.germline_adimab_imgt_lu(
	adimab_gene_name TEXT PRIMARY KEY,
	imgt_gene_name TEXT
);
COMMENT ON TABLE antibodies.germline_adimab_imgt_lu IS
$$
Maps the germline names in the Adimab spreadsheets to IMGT names.
IMGT links:
VH source = http://www.imgt.org/IMGTrepertoire/Proteins/alleles/list_alleles.php?species=Homo%20sapiens&group=IGHV
VK source = http://www.imgt.org/IMGTrepertoire/Proteins/alleles/list_alleles.php?species=Homo%20sapiens&group=IGKV
$$;
-- Load the Adimab-IMGT germline gene names
INSERT INTO antibodies.germline_adimab_imgt_lu(adimab_gene_name, imgt_gene_name) VALUES
('VH4-34', 'IGHV4-34'),
('VH3-21', 'IGHV3-21'),
('VH1-02', 'IGHV1-2'),
('VH1-69', 'IGHV1-69'),
('VH4-31', 'IGHV4-31'),
('VH4-39', 'IGHV4-39'),
('VK1-39', 'IGKV1-39'),
('VK4-01', 'IGKV4-1'),
('VK1-33', 'IGKV1-33'),
('VK3-20', 'IGKV3-20'),
('VK3-11', 'IGKV3-11'),
('VK1-05', 'IGKV1-5');