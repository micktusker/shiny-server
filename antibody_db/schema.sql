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

CREATE TABLE antibodies.mab_sequences(
    mab_full_sequence_hash_id TEXT PRIMARY KEY,
	commonly_known_as TEXT,
    source_database_id TEXT,
	source_database_url TEXT,
	antibody_type TEXT,
	heavy_chain_sequence TEXT,
	light_chain_sequence TEXT
);
COMMENT ON TABLE antibodies.mab_sequences IS
$$
This is where all monoclonal antibody sequences should be stored.
Records should only be inserted using the PL/pgSQL function 'antibodies.add_mab_sequence'.
The primary key is created by this function and constraints on the mab sequence are enforced by this function.
$$;
