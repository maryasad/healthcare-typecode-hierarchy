-- Test Data Script for Healthcare Type Code Hierarchy
-- This script populates the system with realistic test data

-- Clear existing data (if needed)
DELETE FROM tbl_closure;
DELETE FROM tbl_node;

-- Reset identity (if needed)
DBCC CHECKIDENT ('tbl_node', RESEED, 0);

-- 1. ICD-10 Diagnostic Codes (Level 1 - Root)
EXEC sp_add_node 'ICD10-A00-B99', 'Certain infectious and parasitic diseases', 'ICD10', 'CATEGORY';
EXEC sp_add_node 'ICD10-C00-D48', 'Neoplasms', 'ICD10', 'CATEGORY';
EXEC sp_add_node 'ICD10-M00-M99', 'Diseases of the musculoskeletal system', 'ICD10', 'CATEGORY';

-- 2. ICD-10 Subcategories (Level 2)
DECLARE @infectious_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-A00-B99');
DECLARE @neoplasms_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-C00-D48');
DECLARE @musculo_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-M00-M99');

EXEC sp_add_node 'ICD10-A15-A19', 'Tuberculosis', 'ICD10', 'SUBCATEGORY', @infectious_id;
EXEC sp_add_node 'ICD10-C15-C26', 'Malignant neoplasms of digestive organs', 'ICD10', 'SUBCATEGORY', @neoplasms_id;
EXEC sp_add_node 'ICD10-M15-M19', 'Arthrosis', 'ICD10', 'SUBCATEGORY', @musculo_id;

-- 3. SNOMED CT Codes (mapped to ICD-10)
DECLARE @tb_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-A15-A19');
DECLARE @cancer_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-C15-C26');
DECLARE @arthritis_id INT = (SELECT node_id FROM tbl_node WHERE code = 'ICD10-M15-M19');

EXEC sp_add_node 'SNOMED-154283005', 'Pulmonary tuberculosis', 'SNOMED', 'FINDING', @tb_id;
EXEC sp_add_node 'SNOMED-363349007', 'Malignant tumor of gastric cardia', 'SNOMED', 'DISORDER', @cancer_id;
EXEC sp_add_node 'SNOMED-396275006', 'Osteoarthritis', 'SNOMED', 'DISORDER', @arthritis_id;

-- 4. Local Hospital Codes (mapped to SNOMED)
DECLARE @snomed_tb_id INT = (SELECT node_id FROM tbl_node WHERE code = 'SNOMED-154283005');
DECLARE @snomed_cancer_id INT = (SELECT node_id FROM tbl_node WHERE code = 'SNOMED-363349007');
DECLARE @snomed_arthritis_id INT = (SELECT node_id FROM tbl_node WHERE code = 'SNOMED-396275006');

EXEC sp_add_node 'LOCAL-TB001', 'Tuberculosis - Pulmonary', 'LOCAL', 'DIAGNOSIS', @snomed_tb_id;
EXEC sp_add_node 'LOCAL-CA002', 'Stomach Cancer', 'LOCAL', 'DIAGNOSIS', @snomed_cancer_id;
EXEC sp_add_node 'LOCAL-AR003', 'Osteoarthritis - General', 'LOCAL', 'DIAGNOSIS', @snomed_arthritis_id;

-- 5. Add some specific variations
EXEC sp_add_node 'LOCAL-TB001-A', 'Tuberculosis - Active', 'LOCAL', 'DIAGNOSIS_DETAIL', 
    (SELECT node_id FROM tbl_node WHERE code = 'LOCAL-TB001');
EXEC sp_add_node 'LOCAL-TB001-L', 'Tuberculosis - Latent', 'LOCAL', 'DIAGNOSIS_DETAIL',
    (SELECT node_id FROM tbl_node WHERE code = 'LOCAL-TB001');

-- 6. Add some legacy codes
EXEC sp_add_node 'LEGACY-100', 'Old TB Code', 'LEGACY', 'OLD_SYSTEM',
    (SELECT node_id FROM tbl_node WHERE code = 'LOCAL-TB001');
EXEC sp_add_node 'LEGACY-200', 'Old Cancer Code', 'LEGACY', 'OLD_SYSTEM',
    (SELECT node_id FROM tbl_node WHERE code = 'LOCAL-CA002');

-- Verify data
SELECT 'Node Count' as Metric, COUNT(*) as Value FROM tbl_node
UNION ALL
SELECT 'Closure Count', COUNT(*) FROM tbl_closure
UNION ALL
SELECT 'Root Nodes', COUNT(*) FROM tbl_node n
WHERE NOT EXISTS (
    SELECT 1 FROM tbl_closure c 
    WHERE c.descendant_id = n.node_id 
    AND c.ancestor_id != n.node_id
)
UNION ALL
SELECT 'Leaf Nodes', COUNT(*) FROM tbl_node n
WHERE NOT EXISTS (
    SELECT 1 FROM tbl_closure c 
    WHERE c.ancestor_id = n.node_id 
    AND c.descendant_id != n.node_id
);
