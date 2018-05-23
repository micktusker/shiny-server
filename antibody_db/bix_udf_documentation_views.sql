-- There are a lot of functions here, this view is handy for viewing them.
CREATE OR REPLACE VIEW bix_udfs.vw_custom_functions AS
SELECT 
  p.proname AS funcname,  
  d.description, 
  n.nspname
FROM pg_proc p
  INNER JOIN pg_namespace n ON n.oid = p.pronamespace
    LEFT JOIN pg_description As d ON (d.objoid = p.oid )
WHERE
  nspname = 'bix_udfs'
ORDER BY 
  n.nspname;
COMMENT ON VIEW bix_udfs.vw_custom_functions IS 'Lists all custom functions in the schema "bix_udfs". Taken from http://www.postgresonline.com/journal/archives/215-Querying-table,-view,-column-and-function-descriptions.html.';

-- Create a view to display comments in parsed table
CREATE OR REPLACE VIEW bix_udfs.vw_udf_documentation AS                                        
SELECT
  function_oid,
  function_name,
  function_comment,
  function_comment->>'Purpose' purpose,
  function_comment->>'Example' example_call,
  function_comment->>'Notes' notes,
  function_comment->>'Commenter_Username' comment_added_by,
  function_comment->>'Comment_Date' comment_date
FROM 
  get_function_details_for_schema('bix_udfs', 'NON_STANDARD_COMMENT');                                        
COMMENT ON VIEW bix_udfs.vw_udf_documentation IS 'Uses the UDF get_function_details_for_schema to extract documentation from UDF comments in the schema *bix_udfs*.';
