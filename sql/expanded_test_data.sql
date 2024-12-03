-- Expanded Test Data Script with Comprehensive Healthcare Codes
-- Includes: ICD-10, SNOMED CT, LOINC, Local Codes, and Legacy Systems

-- Clear existing data
DELETE FROM tbl_closure;
DELETE FROM tbl_node;
DBCC CHECKIDENT ('tbl_node', RESEED, 0);

-- 1. ICD-10 Diagnostic Categories (Level 1)
DECLARE @categories TABLE (code VARCHAR(50), description NVARCHAR(MAX));
INSERT INTO @categories VALUES
    ('ICD10-A00-B99', 'Infectious and parasitic diseases'),
    ('ICD10-C00-D48', 'Neoplasms'),
    ('ICD10-E00-E89', 'Endocrine, nutritional and metabolic diseases'),
    ('ICD10-F01-F99', 'Mental and behavioral disorders'),
    ('ICD10-I00-I99', 'Diseases of the circulatory system'),
    ('ICD10-J00-J99', 'Diseases of the respiratory system'),
    ('ICD10-K00-K95', 'Diseases of the digestive system'),
    ('ICD10-M00-M99', 'Diseases of the musculoskeletal system'),
    ('ICD10-N00-N99', 'Diseases of the genitourinary system'),
    ('ICD10-R00-R99', 'Symptoms, signs and abnormal clinical findings');

-- Insert categories
DECLARE @category_cursor CURSOR;
SET @category_cursor = CURSOR FOR SELECT code, description FROM @categories;
DECLARE @code VARCHAR(50), @desc NVARCHAR(MAX);
OPEN @category_cursor;
FETCH NEXT FROM @category_cursor INTO @code, @desc;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC sp_add_node @code, @desc, 'ICD10', 'CATEGORY';
    FETCH NEXT FROM @category_cursor INTO @code, @desc;
END;
CLOSE @category_cursor;
DEALLOCATE @category_cursor;

-- 2. Detailed ICD-10 Subcategories (Level 2)
-- Musculoskeletal System (Example)
DECLARE @musculo_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-M00-M99');
EXEC sp_add_node 'ICD10-M15-M19', 'Osteoarthritis', 'ICD10', 'SUBCATEGORY', @musculo_id;
EXEC sp_add_node 'ICD10-M20-M25', 'Other joint disorders', 'ICD10', 'SUBCATEGORY', @musculo_id;
EXEC sp_add_node 'ICD10-M30-M36', 'Systemic connective tissue disorders', 'ICD10', 'SUBCATEGORY', @musculo_id;
EXEC sp_add_node 'ICD10-M40-M43', 'Deforming dorsopathies', 'ICD10', 'SUBCATEGORY', @musculo_id;
EXEC sp_add_node 'ICD10-M45-M49', 'Spondylopathies', 'ICD10', 'SUBCATEGORY', @musculo_id;
EXEC sp_add_node 'ICD10-M50-M54', 'Other dorsopathies', 'ICD10', 'SUBCATEGORY', @musculo_id;

-- Circulatory System (Example)
DECLARE @circulatory_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-I00-I99');
EXEC sp_add_node 'ICD10-I10-I15', 'Hypertensive diseases', 'ICD10', 'SUBCATEGORY', @circulatory_id;
EXEC sp_add_node 'ICD10-I20-I25', 'Ischemic heart diseases', 'ICD10', 'SUBCATEGORY', @circulatory_id;
EXEC sp_add_node 'ICD10-I26-I28', 'Pulmonary heart disease', 'ICD10', 'SUBCATEGORY', @circulatory_id;
EXEC sp_add_node 'ICD10-I30-I52', 'Other forms of heart disease', 'ICD10', 'SUBCATEGORY', @circulatory_id;

-- 3. SNOMED CT Codes (mapped to ICD-10)
-- Musculoskeletal Conditions
DECLARE @arthritis_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-M15-M19');
EXEC sp_add_node 'SNOMED-396275006', 'Osteoarthritis', 'SNOMED', 'DISORDER', @arthritis_id;
EXEC sp_add_node 'SNOMED-239873007', 'Osteoarthritis of knee', 'SNOMED', 'DISORDER', @arthritis_id;
EXEC sp_add_node 'SNOMED-239872002', 'Osteoarthritis of hip', 'SNOMED', 'DISORDER', @arthritis_id;

-- Cardiac Conditions
DECLARE @cardiac_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-I20-I25');
EXEC sp_add_node 'SNOMED-53741008', 'Coronary arteriosclerosis', 'SNOMED', 'DISORDER', @cardiac_id;
EXEC sp_add_node 'SNOMED-22298006', 'Myocardial infarction', 'SNOMED', 'DISORDER', @cardiac_id;

-- 4. LOINC Laboratory Codes
-- Create LOINC root
EXEC sp_add_node 'LOINC-ROOT', 'Laboratory Observations', 'LOINC', 'CATEGORY';
DECLARE @loinc_root_id INT = (SELECT node_id FROM tbl_node WHERE code = 'LOINC-ROOT');

-- Common Lab Tests
EXEC sp_add_node 'LOINC-1920-8', 'Aspartate aminotransferase [Enzymatic activity/volume]', 'LOINC', 'LAB_TEST', @loinc_root_id;
EXEC sp_add_node 'LOINC-1742-6', 'Alanine aminotransferase [Enzymatic activity/volume]', 'LOINC', 'LAB_TEST', @loinc_root_id;
EXEC sp_add_node 'LOINC-2093-3', 'Cholesterol total [Mass/volume]', 'LOINC', 'LAB_TEST', @loinc_root_id;
EXEC sp_add_node 'LOINC-2085-9', 'HDL Cholesterol', 'LOINC', 'LAB_TEST', @loinc_root_id;
EXEC sp_add_node 'LOINC-2089-1', 'LDL Cholesterol', 'LOINC', 'LAB_TEST', @loinc_root_id;
EXEC sp_add_node 'LOINC-4548-4', 'Hemoglobin A1c', 'LOINC', 'LAB_TEST', @loinc_root_id;

-- 5. Local Hospital Codes (mapped to multiple systems)
-- Radiology Procedures
EXEC sp_add_node 'LOCAL-RAD-ROOT', 'Radiology Procedures', 'LOCAL', 'CATEGORY';
DECLARE @rad_root_id INT = (SELECT node_id FROM tbl_node WHERE code = 'LOCAL-RAD-ROOT');

EXEC sp_add_node 'LOCAL-RAD-XR-KNEE', 'Knee X-Ray', 'LOCAL', 'PROCEDURE', @rad_root_id;
EXEC sp_add_node 'LOCAL-RAD-MRI-KNEE', 'Knee MRI', 'LOCAL', 'PROCEDURE', @rad_root_id;
EXEC sp_add_node 'LOCAL-RAD-CT-CHEST', 'Chest CT', 'LOCAL', 'PROCEDURE', @rad_root_id;
EXEC sp_add_node 'LOCAL-RAD-US-ABD', 'Abdominal Ultrasound', 'LOCAL', 'PROCEDURE', @rad_root_id;

-- Laboratory Orders
EXEC sp_add_node 'LOCAL-LAB-ROOT', 'Laboratory Orders', 'LOCAL', 'CATEGORY';
DECLARE @lab_root_id INT = (SELECT node_id FROM tbl_node WHERE code = 'LOCAL-LAB-ROOT');

-- Map local lab codes to LOINC
DECLARE @loinc_ast_id INT = (SELECT node_id FROM tbl_node WHERE code = 'LOINC-1920-8');
DECLARE @loinc_alt_id INT = (SELECT node_id FROM tbl_node WHERE code = 'LOINC-1742-6');
DECLARE @loinc_chol_id INT = (SELECT node_id FROM tbl_node WHERE code = 'LOINC-2093-3');

EXEC sp_add_node 'LOCAL-LAB-LFT', 'Liver Function Tests', 'LOCAL', 'LAB_PANEL', @lab_root_id;
EXEC sp_add_node 'LOCAL-LAB-AST', 'AST Test', 'LOCAL', 'LAB_TEST', @loinc_ast_id;
EXEC sp_add_node 'LOCAL-LAB-ALT', 'ALT Test', 'LOCAL', 'LAB_TEST', @loinc_alt_id;
EXEC sp_add_node 'LOCAL-LAB-LIPID', 'Lipid Panel', 'LOCAL', 'LAB_PANEL', @loinc_chol_id;

-- 6. Legacy System Codes
EXEC sp_add_node 'LEGACY-ROOT', 'Legacy System Codes', 'LEGACY', 'CATEGORY';
DECLARE @legacy_root_id INT = (SELECT node_id FROM tbl_node WHERE code = 'LEGACY-ROOT');

-- Map legacy codes to current systems
DECLARE @snomed_knee_id INT = (SELECT node_id FROM tbl_node WHERE code = 'SNOMED-239873007');
DECLARE @local_knee_id INT = (SELECT node_id FROM tbl_node WHERE code = 'LOCAL-RAD-XR-KNEE');

EXEC sp_add_node 'LEGACY-ORTHO-100', 'Knee Arthritis (Legacy)', 'LEGACY', 'DIAGNOSIS', @snomed_knee_id;
EXEC sp_add_node 'LEGACY-RAD-200', 'Knee X-Ray (Legacy)', 'LEGACY', 'PROCEDURE', @local_knee_id;

-- 7. Add some specific clinical variations
-- Knee Osteoarthritis Variations
DECLARE @knee_oa_id INT = (SELECT node_id FROM tbl_node WHERE code = 'SNOMED-239873007');
EXEC sp_add_node 'LOCAL-OA-KNEE-1', 'Primary Knee OA', 'LOCAL', 'DIAGNOSIS_DETAIL', @knee_oa_id;
EXEC sp_add_node 'LOCAL-OA-KNEE-2', 'Secondary Knee OA', 'LOCAL', 'DIAGNOSIS_DETAIL', @knee_oa_id;
EXEC sp_add_node 'LOCAL-OA-KNEE-3', 'Post-traumatic Knee OA', 'LOCAL', 'DIAGNOSIS_DETAIL', @knee_oa_id;

-- Verify the data structure
SELECT 'Total Nodes' as Metric, COUNT(*) as Value FROM tbl_node
UNION ALL
SELECT 'Total Relationships', COUNT(*) FROM tbl_closure
UNION ALL
SELECT 'ICD-10 Codes', COUNT(*) FROM tbl_node WHERE source_system = 'ICD10'
UNION ALL
SELECT 'SNOMED Codes', COUNT(*) FROM tbl_node WHERE source_system = 'SNOMED'
UNION ALL
SELECT 'LOINC Codes', COUNT(*) FROM tbl_node WHERE source_system = 'LOINC'
UNION ALL
SELECT 'Local Codes', COUNT(*) FROM tbl_node WHERE source_system = 'LOCAL'
UNION ALL
SELECT 'Legacy Codes', COUNT(*) FROM tbl_node WHERE source_system = 'LEGACY';

-- Add some example queries
-- 1. Find all codes related to knee conditions
SELECT DISTINCT n.code, n.description, n.source_system
FROM tbl_node n
WHERE n.code LIKE '%KNEE%'
OR n.description LIKE '%Knee%'
ORDER BY n.source_system, n.code;

-- 2. Show complete mapping chain for knee osteoarthritis
WITH KneeOA AS (
    SELECT n1.code as source_code,
           n1.source_system as source_system,
           n2.code as related_code,
           n2.source_system as related_system,
           c1.path_length
    FROM tbl_node n1
    JOIN tbl_closure c1 ON n1.node_id = c1.descendant_id
    JOIN tbl_node n2 ON c1.ancestor_id = n2.node_id
    WHERE n1.code = 'LOCAL-OA-KNEE-1'
)
SELECT *
FROM KneeOA
ORDER BY path_length;
