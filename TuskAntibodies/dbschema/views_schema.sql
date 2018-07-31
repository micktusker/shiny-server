CREATE OR REPLACE VIEW ab_data.vw_antibodies_information_and_sequence AS
SELECT
  sq1.antibody_name,
  sq1.h_chain_sequence,
  sq2.l_chain_sequence,
  sq1.target_gene_name
FROM
  (SELECT
    ab.antibody_name,
    cs.amino_acid_sequence h_chain_sequence,
    cs.target_gene_name
  FROM
    ab_data.antibodies ab
    JOIN
      ab_data.antibody_to_chain_sequence ab2cs
        ON
          ab.antibody_name = ab2cs.antibody_name
    JOIN
      ab_data.chain_sequences cs
      ON
        ab2cs.sequence_name = cs.sequence_name
   WHERE
     cs.chain_type = 'H') sq1
  FULL OUTER JOIN
  (SELECT
    ab.antibody_name,
    cs.amino_acid_sequence l_chain_sequence,
    cs.target_gene_name
  FROM
    ab_data.antibodies ab
    JOIN
      ab_data.antibody_to_chain_sequence ab2cs
        ON
          ab.antibody_name = ab2cs.antibody_name
    JOIN
      ab_data.chain_sequences cs
      ON
        ab2cs.sequence_name = cs.sequence_name
   WHERE
     cs.chain_type = 'L') sq2
  ON
    sq1.antibody_name = sq2.antibody_name;
COMMENT ON VIEW ab_data.vw_antibodies_information_and_sequence IS 'Summary view of all antibody data matched to sequences. Thisview is used by the R Shiny application';

CREATE OR REPLACE VIEW ab_data.vw_duplicated_sequences AS
SELECT
  sequence_hash_id,
  ARRAY_AGG(sequence_name) sequence_names
FROM
  ab_data.chain_sequences
GROUP BY
  sequence_hash_id
HAVING
  COUNT(sequence_name) > 1;
COMMENT ON VIEW ab_data.vw_duplicated_sequences IS 'Returns rows where the same sequence is shared by different sequence names.';




GRANT USAGE ON SCHEMA ab_data TO mabmindergroup;
GRANT INSERT, UPDATE, DELETE, SELECT ON ALL TABLES IN SCHEMA ab_data TO mabmindergroup;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ab_data TO mabmindergroup;


