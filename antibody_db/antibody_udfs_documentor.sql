SELECT create_function_comment_statement(
  'antibodies.add_new_antibody_sequence',
  ARRAY['TEXT', 'TEXT', 'TEXT'],
  'Adds an antibody sequence with a name and optional metadata to the databaseand returns a JSONB response with information on the database operations performed.',
  $$SELECT * FROM antibodies.add_new_antibody_sequence('test ab 1', 'EVQLLESGGGLVQ', '{' || CHR(34) || 'adimab_id' || CHR(34) || ': 686}')$$,
  'The input sequence and antibody name are stripped of white space and changed to upper case before any INSERT is called. ' ||
  'The function calls two INSERT statements, each within their own BEGIN..END blocks to allow fine-grained exception handling and reporting.  ' ||
  'These two INSERT statements update the |aa_sequences| and |aa_sequence_metadata| tables. ' ||
  'The target table of the INSERT for the sequence enforces: ' ||
  '--a CHECK to ensure that only sequences with recognised single amino acid codes are accepted. ' ||
  '--a UNIQUE constraint on the amino acid sequence by calculating an MD5 hash value for the sequence and using this as the primary key. ' ||
  'If this function is called again with the same input sequence but a different antibody name, ' ||
  'a row is added to the metadata table to register the new name but the |aa_sequences| table is NOT updated. ' ||
  'This function will attempt to always return a JSONB response even if an uncaught exception is thrown.  ' ||
  'The calling code needs to check the returned JSONB for a key named |ERROR| to determine if an exception was thrown. ');
  
  
  
  