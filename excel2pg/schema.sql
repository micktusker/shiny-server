CREATE OR REPLACE FUNCTION convert_excel_date_number_to_date(p_excel_date_number INTEGER)
RETURNS DATE
AS
$$
BEGIN
  RETURN (TO_DATE('1900-01-01', 'YYYY-MM-DD') -2) + p_excel_date_number;
END;
$$
LANGUAGE plpgsql
STABLE
SECURITY DEFINER;

COMMENT ON FUNCTION convert_excel_date_number_to_date(INTEGER) IS
$qq$
Purpose:R library function "readxl::read_xlsx" converts Excel dates into the date serial number representation.
This function converts those numbers into the correct date formats that can be recognised by PostgreSQL.
Invocation: SELECT convert_excel_date_number_to_date(42815); 
Note: This Excel function call will return the same date: =TEXT(42815,"dd-mm-yyyy")
See MS documentation on Excel date formats: https://support.office.com/en-gb/article/Convert-dates-stored-as-text-to-dates-8df7663e-98e6-4295-96e4-32a67ec0a680
$qq$;
