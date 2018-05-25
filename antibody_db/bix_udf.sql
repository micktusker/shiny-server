CREATE OR REPLACE FUNCTION bix_udfs.get_ensembl_json(p_ext TEXT)
RETURNS JSONB 
AS
$$
	import requests
	import json
    
	server = "https://rest.ensembl.org"
	response = requests.get(server + p_ext, headers={ "Content-Type" : "application/json"})
	if not response.ok:
		response.raise_for_status()
 	return json.dumps(response.json())
$$
LANGUAGE 'plpythonu'
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_details_for_id_as_json(p_identifier TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_rest_url_ext TEXT := '/lookup/id/%s?expand=1';
  l_gene_details JSONB;
BEGIN
  IF p_identifier !~ E'^ENS' THEN
    RAISE EXCEPTION 'The given identifier "%s" is invalid!', p_identifier;
  END IF;
  l_rest_url_ext := FORMAT(l_rest_url_ext, p_identifier);
  l_gene_details := bix_udfs.get_ensembl_json(l_rest_url_ext);
  RETURN l_gene_details;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;


CREATE OR REPLACE FUNCTION bix_udfs.get_details_for_symbol_as_json(p_symbol TEXT, p_species_name TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_rest_url_ext TEXT := '/lookup/symbol/%s/%s?expand=1';
  l_symbol_details JSONB;
BEGIN
  l_rest_url_ext := FORMAT(l_rest_url_ext, p_species_name, p_symbol);
  l_symbol_details := bix_udfs.get_ensembl_json(l_rest_url_ext);
  RETURN l_symbol_details;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;


CREATE OR REPLACE FUNCTION bix_udfs.get_features_for_genomic_location(p_species_name TEXT, 
								     p_chromosome_name TEXT, 
								     p_feature TEXT, 
								     p_start_pos BIGINT, 
								     p_end_pos BIGINT)
RETURNS JSONB
AS
$$
DECLARE
  l_rest_url_ext TEXT := '/overlap/region/%s/%s:%s-%s?feature=%s';
  l_features_enum TEXT[] := ARRAY['band', 'gene', 'transcript', 'cds', 'exon', 'repeat', 'simple', 'misc', 'variation', 
                                 'somatic_variation', 'structural_variation', 'somatic_structural_variation', 'constrained', 
                                 'regulatory', 'motif', 'chipseq', 'array_probe'];
  l_symbol_details JSONB;
  l_is_feature_in_enum BOOLEAN;
BEGIN
  SELECT p_feature = ANY(l_features_enum) INTO l_is_feature_in_enum;
  IF NOT l_is_feature_in_enum THEN
    RAISE EXCEPTION 'Feature "%s" is not a recognized feature name. Recognized feature names: %s.', p_feature, ARRAY_TO_STRING(l_features_enum, E'\n');
  END IF;
  l_rest_url_ext := FORMAT(l_rest_url_ext, p_species_name, p_chromosome_name, p_start_pos::TEXT, p_end_pos::TEXT, p_feature);
  l_symbol_details := bix_udfs.get_ensembl_json(l_rest_url_ext);
  RETURN l_symbol_details;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_variant_table_for_gene_symbol(p_gene_symbol TEXT, p_species_name TEXT) 
RETURNS TABLE(ensembl_gene_id TEXT, gene_symbol TEXT, variant_id TEXT, consequence_type TEXT, variation_details JSONB)
AS
$$
DECLARE
  l_ensembl_gene_id TEXT;
  l_start BIGINT;
  l_end BIGINT;
  l_chromosome TEXT;
BEGIN
  SELECT
    gene_details->>'id',
    CAST(gene_details->>'start' AS BIGINT),
    CAST(gene_details->>'end' AS BIGINT),
    gene_details->>'seq_region_name'
      INTO l_ensembl_gene_id, l_start, l_end, l_chromosome
  FROM
    (SELECT bix_udfs.get_details_for_symbol_as_json(p_gene_symbol, p_species_name) gene_details) sq;
  RETURN QUERY
  SELECT
    l_ensembl_gene_id ensembl_gene_id,
    p_gene_symbol gene_symbol,
    (jsonb_array_elements(variations))->>'id' variation_id,
    (jsonb_array_elements(variations))->>'consequence_type' consequence_type,
    jsonb_array_elements(variations) variation_details
  FROM
    (SELECT bix_udfs.get_features_for_genomic_location(p_species_name, l_chromosome, 'variation', l_start, l_end) variations) sq;
    
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_variation_info_as_json(p_variation_id TEXT, p_species_name TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_rest_url_ext TEXT := '/variation/%s/%s?content-type=application/json';
  l_variation_details JSONB;
BEGIN
  l_rest_url_ext := FORMAT(l_rest_url_ext, p_species_name, p_variation_id);
  l_variation_details := bix_udfs.get_ensembl_json(l_rest_url_ext);
  RETURN l_variation_details;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_protein_ids_table_for_gene_ids(p_ensembl_gene_id TEXT)
RETURNS TABLE(ensembl_protein_id TEXT, is_canonical TEXT, translation_length INTEGER)
AS
$$
BEGIN
  RETURN QUERY
  SELECT *
  FROM
    (SELECT
      jsonb_array_elements(gene_details->'Transcript')->'Translation'->>'id' ensembl_protein_id,
      jsonb_array_elements(gene_details->'Transcript')->>'is_canonical' is_canonical,
      CAST(jsonb_array_elements(gene_details->'Transcript')->'Translation'->>'length' AS INTEGER) translation_length
    FROM
      (SELECT bix_udfs.get_details_for_id_as_json(p_ensembl_gene_id) gene_details) sqi) sqo
  WHERE
    sqo.ensembl_protein_id IS NOT NULL;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_protein_sequence_as_text_for_gene_id(p_ensembl_gene_id TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_ensembl_protein_id TEXT;
  l_rest_url_ext TEXT := '/sequence/id/%s?content-type=application/json';
  l_sequence_as_json JSONB;
  l_sequence TEXT;
BEGIN
  SELECT ensembl_protein_id INTO l_ensembl_protein_id 
  FROM 
    bix_udfs.get_protein_ids_table_for_gene_ids(p_ensembl_gene_id);
  l_rest_url_ext := FORMAT(l_rest_url_ext, l_ensembl_protein_id);
  l_sequence_as_json := bix_udfs.get_ensembl_json(l_rest_url_ext);
  l_sequence := l_sequence_as_json->>'seq';
  RETURN l_sequence;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_vep_for_variation_id(p_variation_id TEXT, p_species_name TEXT)
RETURNS JSONB
AS
$$
DECLARE
 l_rest_url_ext TEXT := '/vep/%s/id/%s?content-type=application/json';
 l_vep_for_variation_id_json JSONB;
BEGIN
  l_rest_url_ext := FORMAT(l_rest_url_ext, p_species_name, p_variation_id);
  l_vep_for_variation_id_json := bix_udfs.get_ensembl_json(l_rest_url_ext);
  RETURN l_vep_for_variation_id_json;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_gene_id_for_species_name(p_species_name TEXT, p_gene_name TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_gene_details JSONB;
  l_gene_id TEXT;
BEGIN
  l_gene_details := bix_udfs.get_details_for_symbol_as_json(p_gene_name, p_species_name);
  SELECT l_gene_details->>'id' INTO l_gene_id;
  RETURN l_gene_id;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_fastas_for_species_gene(p_species_names TEXT[], p_gene_name TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_species_name TEXT;
  l_ensembl_gene_id TEXT;
  l_gene_aa_sequence TEXT;
  l_gene_sequence_fasta TEXT := '';
BEGIN
  FOREACH l_species_name IN ARRAY p_species_names
  LOOP
    l_ensembl_gene_id := bix_udfs.get_gene_id_for_species_name(l_species_name, p_gene_name);
    l_gene_aa_sequence := bix_udfs.get_protein_sequence_as_text_for_gene_id(l_ensembl_gene_id);
    l_gene_sequence_fasta := l_gene_sequence_fasta || '>' || p_gene_name || '|' || l_species_name || E'\n'
                               || l_gene_aa_sequence || E'\n';
  END LOOP;
  RETURN TRIM(l_gene_sequence_fasta);
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_xref_info_for_ensembl_id(p_ensembl_id TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_rest_url_ext TEXT := '/xrefs/id/%s?content-type=application/json';
  l_xref_info JSONB;
BEGIN
  l_rest_url_ext := FORMAT(l_rest_url_ext, p_ensembl_id);
  l_xref_info := bix_udfs.get_ensembl_json(l_rest_url_ext);
  RETURN l_xref_info;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_xref_table_for_ensembl_id(p_ensembl_id TEXT)
RETURNS TABLE(primary_id TEXT, dbname TEXT)
AS
$$
DECLARE
  l_rest_url_ext TEXT := '/xrefs/id/%s?content-type=application/json';
  l_xref_info JSONB := bix_udfs.get_xref_info_for_ensembl_id(p_ensembl_id);
BEGIN
  RETURN QUERY
  SELECT
    xref_row->>'primary_id',
    xref_row->>'dbname'
  FROM
    (SELECT
       jsonb_array_elements(l_xref_info) xref_row) xref;
END;
$$
LANGUAGE plpgsql
STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_uniprot_id_for_ensembl_gene_id(p_ensembl_gene_id TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_uniprot_id TEXT;
  l_dbname TEXT := 'Uniprot_gn';
BEGIN
  SELECT 
    primary_id INTO STRICT l_uniprot_id 
  FROM 
    bix_udfs.get_xref_table_for_ensembl_id(p_ensembl_gene_id)
  WHERE 
    dbname = l_dbname;
  RETURN l_uniprot_id;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_fasta_for_gene_from_uniprot(p_uniprot_id TEXT)
RETURNS TEXT
AS
$$
	import requests
    
	url = 'http://www.uniprot.org/uniprot/%s.fasta' % p_uniprot_id
	response = requests.get(url, headers={ "Content-Type" : "application/text"})
	if not response.ok:
		response.raise_for_status()
 	return response.text
$$
LANGUAGE 'plpythonu'
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_uniprot_fastas_for_species_gene(p_species_names TEXT[], p_gene_name TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_species_name TEXT;
  l_ensembl_gene_id TEXT;
  l_uniprot_ids TEXT[];
  l_uniprot_id TEXT;
  l_uniprot_fasta TEXT;
  l_uniprot_fastas TEXT := '';
BEGIN
  FOREACH l_species_name IN ARRAY p_species_names
  LOOP
    l_ensembl_gene_id := bix_udfs.get_gene_id_for_species_name(l_species_name, p_gene_name);
    l_uniprot_ids := bix_udfs.get_uniprot_id_array_for_ensembl_gene_id(l_ensembl_gene_id);
    FOREACH l_uniprot_id IN ARRAY l_uniprot_ids
    LOOP
      l_uniprot_fasta := bix_udfs.get_fasta_for_gene_from_uniprot(l_uniprot_id);
      l_uniprot_fastas := l_uniprot_fastas || l_uniprot_fasta;
    END LOOP;
  END LOOP;
  RETURN TRIM(l_uniprot_fastas);
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_uniprot_id_array_for_ensembl_gene_id(p_ensembl_gene_id TEXT)
RETURNS TEXT[]
AS
$$
DECLARE
  l_uniprot_ids TEXT[];
  l_dbname TEXT := 'Uniprot_gn';
BEGIN
  SELECT 
    ARRAY_AGG(primary_id) INTO l_uniprot_ids
  FROM 
    bix_udfs.get_xref_table_for_ensembl_id(p_ensembl_gene_id)
  WHERE 
    dbname = l_dbname;
  RETURN l_uniprot_ids;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_details_for_id_array_as_json(p_ids TEXT[])
RETURNS JSONB[]
AS
$$
DECLARE
  l_id TEXT;
  l_id_details JSONB;
  l_details_all_ids JSONB[] := ARRAY_FILL('{}'::JSONB, ARRAY[ARRAY_LENGTH(p_ids, 1)]);
  l_loop_counter INTEGER := 1;
  l_err_entry JSONB;
BEGIN
  FOREACH l_id IN ARRAY p_ids
  LOOP
    BEGIN
      l_id_details := bix_udfs.get_details_for_id_as_json(l_id);
	  l_details_all_ids[l_loop_counter] := l_id_details;
	  l_loop_counter := l_loop_counter + 1;
	EXCEPTION WHEN OTHERS THEN
	  l_err_entry := (FORMAT('{"ERROR INPUT ID": "%s"}', l_id))::JSONB;
	  l_details_all_ids[l_loop_counter] := l_err_entry;
	  l_loop_counter := l_loop_counter + 1;
	END;
  PERFORM PG_SLEEP(1);
  END LOOP;
  RETURN l_details_all_ids;
END;
$$
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER;

CREATE OR REPLACE FUNCTION bix_udfs.get_xref_for_name_as_jsonb(p_name TEXT)
RETURNS JSONB
AS
$$
DECLARE
  l_url TEXT := FORMAT('/xrefs/name/human/%s', p_name);
  l_xref_for_name_as_jsonb JSONB := bix_udfs.get_ensembl_json(l_url);
BEGIN
  RETURN CAST(l_xref_for_name_as_jsonb AS JSONB);
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_uniprot_accession_for_synonym(p_synonym TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_uniprot_accession TEXT;
BEGIN
  SELECT
    primary_id INTO l_uniprot_accession
  FROM
    (SELECT
       (JSONB_ARRAY_ELEMENTS(get_xref_for_name_as_jsonb))->>'dbname' dbname,
       (JSONB_ARRAY_ELEMENTS(get_xref_for_name_as_jsonb))->>'primary_id' primary_id
     FROM 
       bix_udfs.get_xref_for_name_as_jsonb(p_synonym)) sq
  WHERE
    dbname = 'Uniprot_gn'
    AND
      primary_id ~ '^[PQO]';
  RETURN l_uniprot_accession;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.get_fasta_seq_as_aa_for_gene_synonym(p_gene_synonym TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_uniprot_accession TEXT := bix_udfs.get_uniprot_accession_for_synonym(p_gene_synonym);
  l_fasta_seq_as_aa TEXT;
BEGIN
  l_fasta_seq_as_aa := bix_udfs.get_fasta_for_gene_from_uniprot(l_uniprot_accession);
  RETURN l_fasta_seq_as_aa;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.create_fasta_format(p_description_line_elements TEXT[], 
														p_sequence TEXT, 
														p_seq_wrap_length INTEGER DEFAULT 60)
RETURNS TEXT
AS
$$
DECLARE
  l_description_line TEXT;
  l_regexp TEXT;
  l_sequence_wrapped TEXT;
  l_fasta_format TEXT;
BEGIN
  l_description_line := CONCAT('>', ARRAY_TO_STRING(p_description_line_elements, '|'), CHR(13));
  l_regexp := FORMAT('(.{1,%s})', p_seq_wrap_length);
  l_sequence_wrapped := REGEXP_REPLACE(p_sequence, l_regexp, '\1' || CHR(13), 'g');
  l_fasta_format := CONCAT(l_description_line, l_sequence_wrapped);
  
  RETURN l_fasta_format;
  
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bix_udfs.extract_sequence_from_fasta(p_fasta_sequence TEXT)
RETURNS TEXT
AS
$$
DECLARE
  l_lines TEXT[];
  l_sequence TEXT;
BEGIN
  l_lines := STRING_TO_ARRAY(p_fasta_sequence, E'\n');
  l_sequence := ARRAY_TO_STRING(l_lines[2:], '');
  l_sequence := REGEXP_REPLACE(UPPER(l_sequence), '\s', 'g');
  
  RETURN l_sequence;
  
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;



