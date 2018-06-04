SELECT create_function_comment_statement(
	'antibodies.load_information',
	ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'],
	'Attempt to insert a row into the |information| table and return TRUE if the insert succeeded otherwise return FALSE.',
    $$SELECT load_information FROM antibodies.load_information(UPPER(TRIM('infliximab')), 'Chimeric human-murine IgG1', 'Commercial antibody', NULL, 'https://www.sigmaaldrich.com/content/dam/sigma-aldrich/docs/Sigma/Datasheet/10/msqc9dat.pdf')$$,
	'This function is called as part of a multi-table insert by function |create_new_antibody_sequence_entry|. ' ||
	'If called directly, then other inserts are needed to maintain referential integrity.');


SELECT create_function_comment_statement(
	'antibodies.load_amino_acid_sequence',
	ARRAY['TEXT', 'TEXT', 'TEXT'],
	'Attempt to insert a row into the |amino_acid_sequences| table and return TRUE if the insert succeeded otherwise return FALSE.',
    $$SELECT load_amino_acid_sequence FROM antibodies.load_amino_acid_sequence(antibodies.get_sequence_hash_id('DILLTQSPAILSVSPGERVSFSCRASQFVGSSIHWYQQRTNGSPRLLIKYASESMSGIPSRFSGSGSGTDFTLSINTVESEDIADYYCQQSHSWPFTFGSGTNLEVKRTVAAPSVFIFPPSDEQLKSGTASVVCLLNNFYPREAKVQWKVDNALQSGNSQESVTEQDSKDSTYSLSSTLTLSKADYEKHKVYACEVTHQGLSSPVTKSFNRGEC'), antibodies.get_cleaned_amino_acid_sequence('DILLTQSPAILSVSPGERVSFSCRASQFVGSSIHWYQQRTNGSPRLLIKYASESMSGIPSRFSGSGSGTDFTLSINTVESEDIADYYCQQSHSWPFTFGSGTNLEVKRTVAAPSVFIFPPSDEQLKSGTASVVCLLNNFYPREAKVQWKVDNALQSGNSQESVTEQDSKDSTYSLSSTLTLSKADYEKHKVYACEVTHQGLSSPVTKSFNRGEC'), 'L')$$,
	'This function is called as part of a multi-table insert by function |create_new_antibody_sequence_entry|. ' ||
	'If called directly, then other inserts are needed to maintain referential integrity.');	


SELECT create_function_comment_statement(
	'antibodies.create_new_antibody_sequence_entry',
	ARRAY['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'],
	'Perform inserts on all relevant tables for a given antibody sequence and antibody information and return a text description of the operations performed or error generated',
	$$SELECT create_new_antibody_sequence_entry FROM antibodies.create_new_antibody_sequence_entry('infliximab', 'Chimeric human-murine IgG1', 'Commercial monoclonal', NULL, 'https://www.sigmaaldrich.com/content/dam/sigma-aldrich/docs/Sigma/Datasheet/10/msqc9dat.pdf', 'EVKLEESGGGLVQPGGSMKLSCVASGFIFSNHWMNWVRQSP EKGLEWVAEIRSKSINSATHYAESVKGRFTISRDDSKSAVY LQMTDLRTEDTGVYYCSRNYYGSTYDYWGQGTTLTVSSAST KGPSVFPLAPSSKSTSGGTAALGCLVKDYFPEPVTVSWNSG ALTSGVHTFPAVLQSSGLYSLSSVVTVPSSSLGTQTYICNV NHKPSNTKVDKKVEPKSCDKTHTCPPCPAPELLGGPSVFLF PPKPKDTLMISRTPEVTCVVVDVSHEDPEVKFNWYVDGVEV HNAKTKPREEQYNSTYRVVSVLTVLHQDWLNGKEYKCKVSN KALPAPIEKTISKAKGQPREPQVYTLPPSRDELTKNQVSLT CLVKGFYPSDIAVEWESNGQPENNYKTTPPVLDSDGSFFLY SKLTVDKSRWQQGNVFSCSVMHEALHNHYTQKSLSLSPG ', 'H');$$,
	'This is the function that should be used to create a new antibody entry in the database. ' ||
	'It either directly or indirectly via calls to other functions performs inserts on three tables: |information|, |amino_acid_sequences| and the join table |information_amino_acid_sequences|. ' ||
	'Inserts are performed so that referential integrity is maintained. ' ||
	'Calling code can inspect the returned text to ascertain what operations were performed. ' ||
	'Primary key violations in the join table |information_amino_acid_sequences| are reported ' ||
	'and all other errors will result in a returned string beginning with |ERROR|. Calling code needs to check if an error has been generated.');
	