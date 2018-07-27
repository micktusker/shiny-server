-- Set all antibody names to upper-case and remove leading or trailing white space
UPDATE
  ab_data.antibodies
SET
  antibody_name = UPPER(TRIM(antibody_name));

-- Populate the join table linking antibodies to sequences
INSERT INTO ab_data.antibody_to_chain_sequence(antibody_name, sequence_name)
SELECT
  ab.antibody_name,
  sq.sequence_name
FROM
  ab_data.antibodies ab
JOIN
  (SELECT
     (REGEXP_MATCHES(sequence_name, '(.+)[_]'))[1] antibody_name,
     sequence_name
   FROM
     ab_data.chain_sequences) sq
  ON
    ab.antibody_name = sq.antibody_name;
-- Add the foreign keys	
ALTER TABLE ab_data.antibody_to_chain_sequence
ADD CONSTRAINT ab2seq_ab_fk FOREIGN KEY(antibody_name)
  REFERENCES ab_data.antibodies(antibody_name)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
ALTER TABLE ab_data.antibody_to_chain_sequence
ADD CONSTRAINT ab2seq_chainseq_fk FOREIGN KEY(sequence_name)
  REFERENCES ab_data.chain_sequences(sequence_name)
  ON DELETE CASCADE
  ON UPDATE CASCADE; 

-- Create the foreign key linking antibody_names_lookup to antibodies
-- Set antiby names in antibody_names_lookup to Upper case and trimmed
UPDATE
  ab_data.antibody_names_lookup
SET
  antibody_name = UPPER(TRIM(antibody_name));
-- First delete rows from antibody_names_lookup that do not have a matching antibody_name in antibodies.
DELETE
FROM
  ab_data.antibody_names_lookup
WHERE
  antibody_name IN
(SELECT
  antibody_name
FROM
  ab_data.antibody_names_lookup
EXCEPT
SELECT
  antibody_name
FROM
  ab_data.antibodies);
ALTER TABLE ab_data.antibody_names_lookup
ADD CONSTRAINT abnames_lu_ab_fk FOREIGN KEY(antibody_name)
  REFERENCES ab_data.antibodies(antibody_name)
  ON DELETE CASCADE
  ON UPDATE CASCADE;


