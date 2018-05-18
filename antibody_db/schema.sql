CREATE TABLE antibodies.aa_sequences(
  aa_sequence_id TEXT PRIMARY KEY,
  aa_sequence TEXT NOT NULL,
  CONSTRAINT ck_is_valid_aa_sequence 
  CHECK(aa_sequence ~ '^[ACDEFGHIKLMNPQRSTVWY]+$')
);
  
CREATE TABLE antibodies.aa_sequence_metadata(
  aa_sequence_metadata_id TEXT PRIMARY KEY,
  antibody_name TEXT NOT NULL,
  aa_sequence_id TEXT NOT NULL,
  extra_metadata JSONB NOT NULL,
  CONSTRAINT aa_sequence_metadata_fk FOREIGN KEY(aa_sequence_id)
	REFERENCES antibodies.aa_sequences(aa_sequence_id)
);

CREATE TABLE antibodies.event_logs(
  event_log_id SERIAL PRIMARY KEY,
  event_details JSONB);
