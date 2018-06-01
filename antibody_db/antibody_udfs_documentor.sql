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
  
SELECT create_function_comment_statement(
  'antibodies.get_sequence_hash_id',
   ARRAY['TEXT'],
  'Return the MD5 hash ID for a given amino acid sequence.',
  $$SELECT antibodies.get_sequence_hash_id('EVQLVESGGGLVKPGGSLRLSCAASGFTFASYGMHWVRQAPGKGLEWVAVIWYDASTKYYADSVKGRFTISRDNSKNTLYLQMNSLRAEDTAVYYCARDLGYGDYAAHDYWGQGTLVTVSS');$$,
  'This function will only calculate a hash ID for a text string that contains only valid sinbgle letter amino acid codes. ' ||
  'This rule is enforced by its call to |antibodies.get_cleaned_amino_acid_sequence| and MD5 hash ID is calculated for the return value of this function.');
  
  
 SELECT create_function_comment_statement(
  'antibodies.add_mab_sequence',
   ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'],
  'Loads a Mab record to the table |antibodies.mab_sequences| and returns JSONB with details of the transaction.',
  $$SELECT  add_mab_sequence FROM  antibodies.add_mab_sequence('Dupilumab', 'D10354', 'https://www.genome.jp/dbget-bin/www_bget?dr:D10354', 'Human IgG4', 'EVQLVESGGG LEQPGGSLRL SCAGSGFTFR DYAMTWVRQA PGKGLEWVSS ISGSGGNTYYADSVKGRFTI SRDNSKNTLY LQMNSLRAED TAVYYCAKDR LSITIRPRYY GLDVWGQGTTVTVSSASTKG PSVFPLAPCS RSTSESTAAL GCLVKDYFPE PVTVSWNSGA LTSGVHTFPAVLQSSGLYSL SSVVTVPSSS LGTKTYTCNV DHKPSNTKVD KRVESKYGPP CPPCPAPEFLGGPSVFLFPP KPKDTLMISR TPEVTCVVVD VSQEDPEVQF NWYVDGVEVH NAKTKPREEQFNSTYRVVSV LTVLHQDWLN GKEYKCKVSN KGLPSSIEKT ISKAKGQPRE PQVYTLPPSQEEMTKNQVSL TCLVKGFYPS DIAVEWESNG QPENNYKTTP PVLDSDGSFF LYSRLTVDKSRWQEGNVFSC SVMHEALHNH YTQKSLSLSL G', 'DIVMTQSPLS LPVTPGEPAS ISCRSSQSLL YSIGYNYLDW YLQKSGQSPQ LLIYLGSNRASGVPDRFSGS GSGTDFTLKI SRVEAEDVGF YYCMQALQTP YTFGQGTKLE IKRTVAAPSVFIFPPSDEQL KSGTASVVCL LNNFYPREAK VQWKVDNALQ SGNSQESVTE QDSKDSTYSLSSTLTLSKAD YEKHKVYACE VTHQGLSSPV TKSFNRGEC');$$,
  'This function creates a new record in the |antibodies.mab_sequences| table if one does not already exist. ' ||
  'Each added Mab is assigned a hash ID value calculated from the concatentation of the heavy and light chain sequence ' ||
  'where the heavy chain is always first. If this hash ID already exists in the table, the load operation will not happen and ' ||
  'the returned JSONB will indicate this. Regardless of the outcome, a JSONB string should always be returned that indicates either success ' ||
  'or failure. The calling code can get the status from the JSONB |error_message| key.');


 