CREATE SCHEMA stored_data;
COMMENT ON SCHEMA stored_data IS 'Contains all the data uploaded from Excel files generated by VBA code in Macro workbook "prepare_data_macros" for the "Pan T Cell Assay"';
CREATE TABLE stored_data.pan_tcell_facs_data(
  pan_tcell_facs_data_id SERIAL PRIMARY KEY,
  upload_date DATE DEFAULT CURRENT_DATE,
  experiment_name TEXT NOT NULL,
  raw_data_name TEXT, 
  viable_cells REAL, 
  cd4_mfi_cd137 REAL, 
  cd4_mfi_proliferation REAL, 
  cd4_mfi_cd25 REAL, 
  cd4_percent_proliferation REAL, 
  cd4_percent_cd25 REAL, 
  cd4_percent_cd137 REAL, 
  cd8_mfi_cd137 REAL, 
  cd8_mfi_proliferation REAL, 
  cd8_mfi_cd25 REAL, 
  cd8_percent_proliferation REAL, 
  cd8_percent_cd25 REAL, 
  cd8_percent_cd137 REAL, 
  cd4_cell_number INTEGER, 
  cd8_cell_number INTEGER, 
  sample_identifier TEXT);
COMMENT ON TABLE stored_data.pan_tcell_facs_data IS 'Stores FACS data for the "Pan T Cell Assay" that has been analysed by FlowJo with the sample IDs added using VBA code in the macro sheet "prepare_data_macros.xlsm".';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.pan_tcell_facs_data_id IS 'Auto-generated primary key for table "stored_data.pan_tcell_facs_data"';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.upload_date IS 'The date that the row was inserted into the table "stored_data.pan_tcell_facs_data".';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.experiment_name IS 'The given in the VBA form to the data set processed by the code in "prepare_data_macros.xlsm".';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.raw_data_name IS 'This is generated by the software and contains an embedded plate ID flanked by underscores.';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.viable_cells IS 'viable cells Lymphocytes/ Single Cells/ Single Cells viable cells Freq. of Parent ';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd4_mfi_cd137 IS 'MFI CD137 Lymphocytes/ Single Cells/ Single Cells/ viable cells CD4+ Median CD137';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd4_mfi_proliferation IS 'MFI proliferation Lymphocytes/ Single Cells/ Single Cells/ viable cells CD4+ Median proliferation';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd4_mfi_cd25 IS 'MFI CD25 Lymphocytes/ Single Cells/ Single Cells/ viable cells CD4+ Median CD25';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd4_percent_proliferation IS 'perc prol Lymphocytes/ Single Cells/ Single Cells/ viable cells/ CD4+ %prol histo CD4+ Freq. of Parent ';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd4_percent_cd25 IS 'perc CD25 Lymphocytes/ Single Cells/ Single Cells/ viable cells/ CD4+ CD4+CD25+ Freq. of Parent ';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd4_percent_cd137 IS 'perc CD137 Lymphocytes/ Single Cells/ Single Cells/ viable cells/ CD4+ CD4+CD137+ Freq. of Parent ';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd8_mfi_cd137 IS 'MFI CD137 Lymphocytes/ Single Cells/ Single Cells/ viable cells CD8+ Median CD137';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd8_mfi_proliferation IS 'MFI proliferation Lymphocytes/ Single Cells/ Single Cells/ viable cells CD8+ Median proliferation';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd8_mfi_cd25 IS 'MFI CD25 Lymphocytes/ Single Cells/ Single Cells/ viable cells CD8+ Median CD25';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd8_percent_proliferation IS 'perc prol Lymphocytes/ Single Cells/ Single Cells/ viable cells/ CD8+ %prol histo CD8+ Freq. of Parent ';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd8_percent_cd25 IS 'perc CD25 Lymphocytes/ Single Cells/ Single Cells/ viable cells/ CD8+ CD8+CD25+ Freq. of Parent ';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd8_percent_cd137 IS 'perc CD137 Lymphocytes/ Single Cells/ Single Cells/ viable cells/ CD8+ CD8+CD137+ Freq. of Parent ';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd4_cell_number IS 'To be calculated using a code of some sort';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.cd8_cell_number IS 'To be calculated using a code of some sort';
COMMENT ON COLUMN stored_data.pan_tcell_facs_data.sample_identifier IS 'Extracted from the plate map and matched to the raw_sample_id using the VBA code in "prepare_data_macros.xlsm"';
