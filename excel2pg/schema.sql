CREATE TABLE loaded_excel_files.cord_experiments(
  cord_experiment_id SERIAL PRIMARY KEY,
  cord_id TEXT, 
  Database_name TEXT, 
  database_id TEXT, 
  fold_change REAL, 
  species TEXT, 
  title TEXT, 
  factor TEXT, 
  group_1 TEXT, 
  group_2 TEXT, 
  array_platform TEXT, 
  of_interest TEXT, 
  abs_value TEXT, 
  sign TEXT);

CREATE OR REPLACE FUNCTION transfer_cord_experiments()
RETURNS TABLE(insert_row_count INTEGER)
AS
$$
DECLARE
  l_inserted_row_count INTEGER;
BEGIN
	INSERT INTO loaded_excel_files.cord_experiments(cord_id, database_name, database_id, fold_change, 
	                                                species, title, factor, group_1, group_2, array_platform, of_interest, abs_value, sign)
	SELECT 
	  "CordID", 
	  "Database", 
	  "Datbase ID", 
	  CAST("Fold Change" AS REAL), 
	  "Species", 
	  "Title", 
	  "Factor", 
	  "Group 1", 
	  "Group 2", 
	  "Array Platform", 
	  "Of_Interest", 
	  abs_value, 
	  sign
	FROM
	  public."Experiments";
	GET DIAGNOSTICS l_inserted_row_count := ROW_COUNT;
	DROP TABLE public."Experiments";
	RETURN QUERY 
	SELECT l_inserted_row_count;
END;
$$
LANGUAGE plpgsql;
COMMENT ON FUNCTION transfer_cord_experiments() IS $$Calling stored procedures has not yet been implemented in R but it can be faked as shown in this function. Call: 'SELECT insert_row_count FROM transfer_cord_experiments();'$$
