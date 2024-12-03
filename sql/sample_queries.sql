-- Sample queries demonstrating the hierarchical type code system

-- 1. Add sample nodes
EXEC sp_add_node 'ICD10-A01', 'Typhoid fever', 'ICD10', 'DIAGNOSIS';
EXEC sp_add_node 'SNOMED-1234', 'Typhoid', 'SNOMED', 'DIAGNOSIS', 1; -- Map to ICD10
EXEC sp_add_node 'LOCAL-TF01', 'Typhoid', 'LOCAL', 'DIAGNOSIS', 2; -- Map to SNOMED

-- 2. Query direct relationships
SELECT * FROM vw_direct_relationships
WHERE parent_system = 'ICD10';

-- 3. Find all related codes across systems
SELECT * FROM vw_all_relationships
WHERE ancestor_code = 'ICD10-A01';

-- 4. Get complete ancestry path for a code
SELECT 
    n1.code as code,
    n1.source_system,
    STRING_AGG(n2.code, ' -> ') WITHIN GROUP (ORDER BY c.path_length) as ancestry_path
FROM tbl_node n1
CROSS APPLY fn_get_ancestors(n1.node_id) n2
WHERE n1.code = 'LOCAL-TF01';

-- 5. Find equivalent codes in different systems
SELECT 
    n1.code as source_code,
    n1.source_system as source_system,
    n2.code as equivalent_code,
    n2.source_system as equivalent_system
FROM tbl_closure c1
JOIN tbl_closure c2 ON c1.ancestor_id = c2.ancestor_id
JOIN tbl_node n1 ON c1.descendant_id = n1.node_id
JOIN tbl_node n2 ON c2.descendant_id = n2.node_id
WHERE n1.source_system != n2.source_system;

-- 6. Get all leaf nodes (codes with no children)
SELECT n.*
FROM tbl_node n
LEFT JOIN tbl_closure c ON n.node_id = c.ancestor_id
WHERE c.path_length = 1
GROUP BY n.node_id, n.code, n.description, n.source_system
HAVING COUNT(*) = 0;

-- 7. Find codes that map across all systems
WITH CodeSystems AS (
    SELECT DISTINCT source_system
    FROM tbl_node
)
SELECT 
    n1.code,
    n1.source_system,
    COUNT(DISTINCT n2.source_system) as mapped_systems_count
FROM tbl_node n1
JOIN tbl_closure c1 ON n1.node_id = c1.ancestor_id
JOIN tbl_node n2 ON c1.descendant_id = n2.node_id
GROUP BY n1.code, n1.source_system
HAVING COUNT(DISTINCT n2.source_system) = (SELECT COUNT(*) FROM CodeSystems);

-- 8. Validate hierarchy integrity
SELECT 
    n1.code as problematic_code,
    n1.source_system
FROM tbl_node n1
LEFT JOIN tbl_closure c ON n1.node_id = c.descendant_id
WHERE c.ancestor_id IS NULL
AND n1.node_id != c.descendant_id;

-- 9. Find most frequently mapped codes
SELECT 
    n1.code,
    n1.source_system,
    COUNT(DISTINCT n2.node_id) as mapping_count
FROM tbl_node n1
JOIN tbl_closure c ON n1.node_id = c.ancestor_id
JOIN tbl_node n2 ON c.descendant_id = n2.node_id
WHERE n1.node_id != n2.node_id
GROUP BY n1.code, n1.source_system
ORDER BY mapping_count DESC;
