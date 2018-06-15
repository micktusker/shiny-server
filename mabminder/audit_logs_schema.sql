DROP SCHEMA IF EXISTS audit_logs CASCADE;
CREATE SCHEMA audit_logs;
COMMENT ON SCHEMA audit_logs IS 'Contains all data and lookup tables for the TUSK antibody-tracking application';


CREATE TABLE audit_logs.data_load_logs(
    data_load_log_id SERIAL PRIMARY KEY,
	loaded_by TEXT DEFAULT CURRENT_USER,
	load_date TIMESTAMPTZ DEFAULT NOW(),
	load_outcome TEXT NOT NULL -- client code can insert the return value of a PL/pgSQL loading function
);

CREATE TABLE audit_logs.update_delete_log (
	update_delete_log_id SERIAL PRIMARY KEY,
    username TEXT, -- who did the change
    event_time TIMESTAMPTZ, -- when the event was recorded
    table_name_target TEXT, -- contains schema-qualified table name
    operation TEXT, -- INSERT, UPDATE, DELETE or TRUNCATE
    before_value JSONB, -- the OLD tuple value
    after_value JSONB -- the NEW tuple value
);

-- Trigger functions
CREATE OR REPLACE FUNCTION audit_logs.audit_trigger() 
  RETURNS trigger AS $$ 
DECLARE 
    old_row JSONB := NULL; 
    new_row JSONB := NULL; 
BEGIN 
    IF TG_OP IN ('UPDATE','DELETE') THEN 
        old_row = row_to_json(OLD); 
    END IF; 
    IF TG_OP IN ('INSERT','UPDATE') THEN 
        new_row = row_to_json(NEW); 
    END IF; 
    INSERT INTO  audit_logs.update_delete_log( 
        username, 
        event_time, 
        table_name_target, 
        operation, 
        before_value, 
        after_value 
    ) VALUES ( 
        CURRENT_USER, 
        NOW(), 
        TG_TABLE_SCHEMA ||  '.' || TG_TABLE_NAME, 
        TG_OP, 
        old_row, 
        new_row 
    ); 
    RETURN NEW; 
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_logs.set_modified_trigger()
RETURNS TRIGGER AS $$
  BEGIN
NEW.last_modified_date = NOW();
NEW.modified_by = CURRENT_USER;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Attach the triggers
-- modification time and user triggers
DROP TRIGGER IF EXISTS set_modified_aas_trg ON ab_data.amino_acid_sequences;
CREATE TRIGGER set_modified_aas_trg
  BEFORE UPDATE
  ON ab_data.amino_acid_sequences 
  FOR EACH ROW 
EXECUTE PROCEDURE audit_logs.set_modified_trigger();

DROP TRIGGER IF EXISTS set_modified_ai_trg ON ab_data.antibody_information;
CREATE TRIGGER set_modified_ai_trg
  BEFORE UPDATE
  ON ab_data.antibody_information 
  FOR EACH ROW 
EXECUTE PROCEDURE audit_logs.set_modified_trigger();

DROP TRIGGER IF EXISTS set_modified_paas_trg ON ab_data.progeny_amino_acid_sequences;
CREATE TRIGGER set_modified_paas_trg
  BEFORE UPDATE
  ON ab_data.progeny_amino_acid_sequences 
  FOR EACH ROW 
EXECUTE PROCEDURE audit_logs.set_modified_trigger();

DROP TRIGGER IF EXISTS set_modified_sti_trg ON ab_data.sequence_to_information;
CREATE TRIGGER set_modified_sti_trg
  BEFORE UPDATE
  ON ab_data.sequence_to_information 
  FOR EACH ROW 
EXECUTE PROCEDURE audit_logs.set_modified_trigger();

-- audit triggers
DROP TRIGGER IF EXISTS update_delete_aas_trg ON ab_data.amino_acid_sequences;
CREATE TRIGGER update_delete_aas_trg 
  AFTER UPDATE OR DELETE 
  ON ab_data.amino_acid_sequences 
  FOR EACH ROW 
EXECUTE PROCEDURE audit_logs.audit_trigger(); 

DROP TRIGGER IF EXISTS update_delete_ai_trg ON ab_data.antibody_information;
CREATE TRIGGER update_delete_ai_trg 
  AFTER UPDATE OR DELETE 
  ON ab_data.antibody_information 
  FOR EACH ROW 
EXECUTE PROCEDURE audit_logs.audit_trigger(); 

DROP TRIGGER IF EXISTS update_delete_paas_trg ON ab_data.progeny_amino_acid_sequences;
CREATE TRIGGER update_delete_paas_trg 
  AFTER UPDATE OR DELETE 
  ON ab_data.progeny_amino_acid_sequences
  FOR EACH ROW 
EXECUTE PROCEDURE audit_logs.audit_trigger();

DROP TRIGGER IF EXISTS update_delete_sti_trg ON ab_data.sequence_to_information;
CREATE TRIGGER update_delete_sti_trg 
  AFTER UPDATE OR DELETE 
  ON ab_data.sequence_to_information 
  FOR EACH ROW 
EXECUTE PROCEDURE audit_logs.audit_trigger();


-- Reset permissions on re-created schema and its objects
GRANT USAGE ON SCHEMA audit_logs TO mabmindergroup;
GRANT INSERT, SELECT ON ALL TABLES IN SCHEMA audit_logs  TO mabmindergroup;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA audit_logs TO mabmindergroup;
