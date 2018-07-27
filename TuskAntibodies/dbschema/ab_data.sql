DROP SCHEMA IF EXISTS ab_data CASCADE;
CREATE SCHEMA ab_data;
COMMENT ON SCHEMA ab_data IS 'Contains all data and lookup tables for the TUSK antibody-tracking application';

CREATE TABLE ab_data.antibodies(
    antibody_name TEXT PRIMARY KEY, --The identifier used to refer to the antibody, for Tusk Abs, it is the Tusk ID itself
    antibody_source TEXT, -- Tusk, Marketed Therapeutic, Research
	antibody_description TEXT, -- Contains any descriptive information of interest.
    created_by TEXT DEFAULT CURRENT_USER,
    date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by TEXT DEFAULT CURRENT_USER	
);
COMMENT ON TABLE ab_data.antibodies IS 'Records bare minimum information for an antibody. More basic information is stored with the sequences.'

CREATE TABLE ab_data.antibody_to_chain_sequence(
    antibody_name TEXT NOT NULL, -- References antibodies
    sequence_hash_id TEXT NOT NULL, -- references chain sequences
	PRIMARY KEY(antibody_name, sequence_hash_id)
);
COMMENT ON TABLE ab_data.antibody_to_chain_sequence IS 'Join table that associates antibody names to their chain sequences';

CREATE TABLE ab_data.chain_sequences(
	sequence_hash_id TEXT PRIMARY KEY, -- The MD5 value for the amino acid sequence where are amino acid symbols are upper-case and where white space has been removed
	sequence_name TEXT UNIQUE NOT NULL, -- If not given, then append the chain type (H or L to the antibody name
	sequence_description TEXT, -- Place for some descriptive text about the sequence.
	amino_acid_sequence TEXT NOT NULL, -- The single letter amino acid sequence of the chain. Sometimes just the VH or VL segment.
	chain_type TEXT NOT NULL, -- H or L for "heavy" and "Light"
	ig_subclass TEXT NOT NULL, -- IgG1, 2, 3, 4. If known. If not known, set as "UNKNOWN". For L chains set as "NA" for "Not Applicable"
	species_name TEXT NOT NULL, -- Human, Mouse, Rat, Chimeric. If unknown, set as 'UNKNOWN',
	sequence_source TEXT NOT NULL, -- File name (Tusk) URL for some commercial antibodies
	created_by TEXT DEFAULT CURRENT_USER,
    date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_by TEXT DEFAULT CURRENT_USER	
);
COMMENT ON TABLE ab_data.chain_sequences IS 'Records all information relating to the amino acid sequences of antibodies stored in the database.';

