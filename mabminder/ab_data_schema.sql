DROP SCHEMA IF EXISTS ab_data CASCADE;
CREATE SCHEMA ab_data;
COMMENT ON SCHEMA ab_data IS 'Contains all data and lookup tables for the TUSK antibody-tracking application';

/**
Links:
Triggers
https://x-team.com/blog/automatic-timestamps-with-postgresql/
Setting up accounts
https://dba.stackexchange.com/questions/117109/how-to-manage-default-privileges-for-users-on-a-database-vs-schema

Setting up
Logged in as postgres:
postgres=# CREATE ROLE micktusker -- superuser created by postgres
postgres=# ALTER USER micktusker WITH CREATEROLE;
postgres=# CREATE DATABASE mabminder;
postgres=# GRANT ALL PRIVILEGES ON DATABASE mabminder TO micktusker;
postgres=# CREATE ROLE mabmindergroup;
postgres=# CREATE ROLE <role name> PASSWORD <pwd>;
postgres=# GRANT mabmindergroup TO "michael.maguire@tusktherapeutics.com";
postgres=# GRANT CONNECT ON DATABASE mabminder TO mabmindergroup;



**/


-- lookup tables
CREATE TABLE ab_data.usernames(
  	username TEXT PRIMARY KEY
);
INSERT INTO ab_data.usernames(username) VALUES('michael.maguire@tusktherapeutics.com'), ('Sabrina.Boussouf@tusktherapeutics.com');

CREATE TABLE ab_data.antibody_sources(
  source_name TEXT PRIMARY KEY
);
INSERT INTO ab_data.antibody_sources(source_name) VALUES('Tusk'), ('Commercial therapeutic'), ('Research'), ('Other');

CREATE TABLE ab_data.antibody_types(
  antibody_type TEXT PRIMARY KEY
);
INSERT INTO ab_data.antibody_types(antibody_type) VALUES('mIgG2a'), ('BiTEs'), ('Chimeric human-murine IgG1'), ('Chimeric IgG1'), ('Chimeric IgG1κ'), ('Chimeric (mouse/human) IgG1/κ'), ('Human FaB'), ('Human IgG1'), ('Human IgG1/κ'), ('Human IgG2'), ('Human IgG2/κ'), ('Human IgG4'), ('Humanized IgG1'), ('Murine IgG2a');


-- data tables
CREATE TABLE ab_data.amino_acid_sequences(
  amino_acid_sequence_id TEXT PRIMARY KEY,
  amino_acid_sequence TEXT NOT NULL,
  chain_type TEXT,
  sequence_name TEXT NOT NULL,
  created_by TEXT NOT NULL DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
  date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified_by TEXT  NOT NULL DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username)
);

CREATE TABLE ab_data.progeny_amino_acid_sequences(
  amino_acid_progeny_sequence_id TEXT NOT NULL PRIMARY KEY,
  amino_acid_parent_sequence_id  TEXT NOT NULL,
  created_by TEXT NOT NULL DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
  date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_modified_date TIMESTAMPTZ NOT NULL  DEFAULT NOW(),
  modified_by TEXT  NOT NULL DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username)
);

CREATE TABLE ab_data.antibody_information(
  common_identifier TEXT PRIMARY KEY,
  antibody_type TEXT NOT NULL REFERENCES ab_data.antibody_types(antibody_type),
  target_gene_name TEXT,
  antibody_source TEXT REFERENCES ab_data.antibody_sources(source_name),
  antibody_url TEXT,
  created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
  date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username)	
);

CREATE TABLE ab_data.sequences_to_information(
  common_identifier TEXT NOT NULL,
  amino_acid_sequence_id TEXT NOT NULL,
  created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
  date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username)	
);

-- Attaching documents to antibody records
CREATE TABLE ab_data.antibody_documents(
    file_checksum TEXT NOT NULL PRIMARY KEY,
    document_name TEXT NOT NULL,
    document_description TEXT,
    created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
    date_added TIMESTAMPTZ  DEFAULT NOW() NOT NULL,
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by text DEFAULT CURRENT_USER
);

CREATE TABLE ab_data.documents_to_antibodies(
    common_identifier TEXT NOT NULL,
    file_checksum TEXT NOT NULL,
    created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
    date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by text DEFAULT CURRENT_USER,
    PRIMARY KEY(common_identifier, file_checksum)
);

-- Attach notes to antibody records
CREATE TABLE ab_data.antibody_notes(
    antibody_note_id SERIAL PRIMARY KEY,
	note_text TEXT,
	created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
    date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by text DEFAULT CURRENT_USER
);

CREATE TABLE ab_data.antibody_notes_to_information(
    common_identifier TEXT NOT NULL,
	antibody_note_id INTEGER,
	created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
    date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by text DEFAULT CURRENT_USER,
	PRIMARY KEY(common_identifier, antibody_note_id)
);


-- Attach notes to sequences
CREATE TABLE ab_data.sequence_notes(
	sequence_note_id SERIAL PRIMARY KEY,
	note_text TEXT,
	created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
    date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by text DEFAULT CURRENT_USER
);

CREATE TABLE ab_data.seq_notes_to_aa_seq(
	amino_acid_sequence_id TEXT NOT NULL,
	sequence_note_id INTEGER,
	created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
    date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by text DEFAULT CURRENT_USER,
	PRIMARY KEY(amino_acid_sequence_id, sequence_note_id)
);
	
CREATE TABLE ab_data.antibody_synonym_types(
    antibody_synonym_type TEXT PRIMARY KEY
);
INSERT INTO ab_data.antibody_synonym_types(antibody_synonym_type) VALUES('ADI_NAME'), ('EXTERNAL_ANTIBODY_NAME'), ('TUSK_NAME');

CREATE TABLE ab_data.antibody_names_lookup(
    antibody_names_lookup_id SERIAL PRIMARY KEY,
	common_identifier TEXT NOT NULL,
	antibody_synonym_type TEXT NOT NULL REFERENCES ab_data.antibody_synonym_types(antibody_synonym_type),
	alternative_name TEXT NOT NULL,
    created_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username),
    date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by TEXT DEFAULT CURRENT_USER REFERENCES ab_data.usernames(username)	
);


-- Add keys
ALTER TABLE ab_data.sequences_to_information
ADD CONSTRAINT seq_to_info_pk PRIMARY KEY(amino_acid_sequence_id, common_identifier);

ALTER TABLE ab_data.sequences_to_information
ADD CONSTRAINT seq_to_info_seq_fk FOREIGN KEY(amino_acid_sequence_id)
REFERENCES ab_data.amino_acid_sequences(amino_acid_sequence_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE ab_data.sequences_to_information
ADD CONSTRAINT seq_to_info_info_fk FOREIGN KEY(common_identifier)
REFERENCES ab_data.antibody_information(common_identifier)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE ab_data.progeny_amino_acid_sequences
ADD CONSTRAINT prog_aa_seq_prog_fk FOREIGN KEY(amino_acid_progeny_sequence_id) 
REFERENCES ab_data.amino_acid_sequences(amino_acid_sequence_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE ab_data.progeny_amino_acid_sequences
ADD CONSTRAINT prog_aa_seq_par_fk FOREIGN KEY(amino_acid_parent_sequence_id) 
REFERENCES ab_data.amino_acid_sequences(amino_acid_sequence_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE ab_data.documents_to_antibodies
ADD CONSTRAINT assoc_doc_doc_fk FOREIGN KEY(file_checksum)
	REFERENCES ab_data.antibody_documents(file_checksum)
    ON DELETE CASCADE
	ON UPDATE CASCADE;

ALTER TABLE ab_data.documents_to_antibodies
ADD CONSTRAINT assoc_doc_ab_fk FOREIGN KEY(common_identifier)
	REFERENCES ab_data.antibody_information(common_identifier)
    ON DELETE CASCADE
	ON UPDATE CASCADE;
	
ALTER TABLE ab_data.antibody_notes_to_information
ADD CONSTRAINT ab_notes_ab_fk FOREIGN KEY(common_identifier)
REFERENCES ab_data.antibody_information(common_identifier)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  
ALTER TABLE ab_data.antibody_notes_to_information
ADD CONSTRAINT ab_notes_notes_fk FOREIGN KEY(antibody_note_id)
REFERENCES ab_data.antibody_notes(antibody_note_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

ALTER TABLE ab_data.seq_notes_to_aa_seq
ADD CONSTRAINT seq_notes_to_aa_seq_seq_fk FOREIGN KEY(amino_acid_sequence_id)
REFERENCES ab_data.amino_acid_sequences(amino_acid_sequence_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE ab_data.seq_notes_to_aa_seq
ADD CONSTRAINT seq_notes_to_aa_seq_seqnotes_fk FOREIGN KEY(sequence_note_id)
REFERENCES ab_data.sequence_notes(sequence_note_id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE ab_data.antibody_names_lookup
ADD CONSTRAINT ab_names_lu_ab_info_fk FOREIGN KEY(common_identifier)
REFERENCES ab_data.antibody_information(common_identifier)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

-- VIEWS
CREATE OR REPLACE VIEW ab_data.vw_antibodies_information_and_sequence AS
SELECT
  sq1.common_identifier,
  sq1.antibody_type,
  sq1.target_gene_name,
  sq1.h_chain_sequence,
  sq2.l_chain_sequence,
  sq1.antibody_url,
  sq1.antibody_source
FROM
  (SELECT
    ai.common_identifier,
    ai.antibody_type,
    ai.target_gene_name,
    ai.antibody_source,
    ai.antibody_url,
    aas.amino_acid_sequence h_chain_sequence
  FROM
    ab_data.antibody_information ai
    JOIN
      ab_data.sequences_to_information sti
        ON
          ai.common_identifier = sti.common_identifier
    JOIN
      ab_data.amino_acid_sequences aas
      ON
        sti.amino_acid_sequence_id = aas.amino_acid_sequence_id
   WHERE
     aas.chain_type = 'H') sq1
  FULL OUTER JOIN
  (SELECT
    ai.common_identifier,
    ai.antibody_type,
    ai.target_gene_name,
    aas.amino_acid_sequence l_chain_sequence
  FROM
    ab_data.antibody_information ai
    JOIN
      ab_data.sequences_to_information sti
        ON
          ai.common_identifier = sti.common_identifier
    JOIN
      ab_data.amino_acid_sequences aas
      ON
        sti.amino_acid_sequence_id = aas.amino_acid_sequence_id
   WHERE
     aas.chain_type = 'L') sq2
  ON
    sq1.common_identifier = sq2.common_identifier;

CREATE OR REPLACE VIEW ab_data.vw_amino_acid_sequences_not_linked_to_ab AS
SELECT *
FROM
  ab_data.amino_acid_sequences
WHERE
  amino_acid_sequence_id IN(
  SELECT
    aas.amino_acid_sequence_id
  FROM
    ab_data.amino_acid_sequences aas
  EXCEPT  
  SELECT
    sti.amino_acid_sequence_id
  FROM
    ab_data.sequences_to_information sti);

-- Used do populate client lists for parent-progeny definition
CREATE OR REPLACE VIEW ab_data.vw_seqname_chaintype_targetgene AS
SELECT 
  aas.sequence_name,
  aas.chain_type,
  ai.target_gene_name
FROM
 ab_data.amino_acid_sequences aas
 JOIN
   ab_data.sequences_to_information sti
   ON
     aas.amino_acid_sequence_id = sti.amino_acid_sequence_id
  JOIN
    ab_data.antibody_information ai
	ON
	  sti.common_identifier = ai.common_identifier;
	  
CREATE OR REPLACE VIEW ab_data.vw_parent_progeny_seq_names AS
SELECT
  sq.parent_sequence_name,
  aas_outer.sequence_name progeny_sequence_name
FROM
  (SELECT
     aas.sequence_name parent_sequence_name,
     paas.amino_acid_progeny_sequence_id progeny_seq_id
   FROM
     ab_data.progeny_amino_acid_sequences paas
     JOIN
       ab_data.amino_acid_sequences aas
	   ON
	     paas.amino_acid_parent_sequence_id = aas.amino_acid_sequence_id) sq
  JOIN
    ab_data.amino_acid_sequences aas_outer
	ON
	  sq.progeny_seq_id = aas_outer.amino_acid_sequence_id;
COMMENT ON VIEW ab_data.vw_parent_progeny_seq_names IS 'Convenience view that maps parent sequence names to their progeny names.';  

-- Germline Gene tables
CREATE TABLE ab_data.germline_genes(
	hgnc_id TEXT PRIMARY KEY, 
	gene_symbol TEXT, 
	gene_name TEXT, 
	ensembl_gene_id TEXT, 
	uniprot_id TEXT, 
	imgt_gene_name TEXT);

CREATE TABLE ab_data.germline_gene_aa_sequences(
    amino_acid_hashed_id TEXT,
	amino_acid_sequence_ensembl TEXT,
	ensembl_gene_id TEXT PRIMARY KEY,
	err_msg TEXT
);

-- Reset permissions on re-created schema and its objects
GRANT USAGE ON SCHEMA ab_data TO mabmindergroup;
GRANT INSERT, UPDATE, DELETE, SELECT ON ALL TABLES IN SCHEMA ab_data TO mabmindergroup;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ab_data TO mabmindergroup;

-- Remove edit permissions on lookup tables for non-admin users
REVOKE ALL ON ab_data.antibody_sources FROM mabmindergroup;
GRANT SELECT ON ab_data.antibody_sources TO mabmindergroup;
REVOKE ALL ON ab_data.antibody_types FROM mabmindergroup;
GRANT SELECT ON ab_data.antibody_types TO mabmindergroup;
REVOKE ALL ON ab_data.usernames FROM mabmindergroup;
GRANT SELECT ON ab_data.usernames TO mabmindergroup;


