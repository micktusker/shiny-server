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
