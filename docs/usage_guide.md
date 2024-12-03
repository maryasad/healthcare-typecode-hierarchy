# Healthcare Type Code Hierarchy - Usage Guide

## Common Scenarios

### 1. Code Mapping Between Systems
```sql
-- Find equivalent codes across systems
SELECT 
    n1.code as source_code,
    n1.source_system as source_system,
    n2.code as target_code,
    n2.source_system as target_system
FROM tbl_node n1
JOIN tbl_closure c1 ON n1.node_id = c1.descendant_id
JOIN tbl_closure c2 ON c1.ancestor_id = c2.ancestor_id
JOIN tbl_node n2 ON c2.descendant_id = n2.node_id
WHERE n1.source_system = 'LOCAL'
AND n2.source_system = 'ICD10';
```

### 2. Hierarchical Navigation
```sql
-- Get complete ancestry path
WITH RecursivePath AS (
    SELECT 
        n.node_id,
        n.code,
        CAST(n.code AS VARCHAR(MAX)) as path
    FROM tbl_node n
    WHERE n.code = 'LOCAL-TB001'
    
    UNION ALL
    
    SELECT 
        n.node_id,
        n.code,
        CAST(n.code + ' -> ' + rp.path AS VARCHAR(MAX))
    FROM tbl_node n
    JOIN tbl_closure c ON n.node_id = c.ancestor_id
    JOIN RecursivePath rp ON c.descendant_id = rp.node_id
    WHERE c.path_length = 1
)
SELECT TOP 1 path
FROM RecursivePath
ORDER BY LEN(path) DESC;
```

### 3. Code Validation
```sql
-- Validate if a code exists in target system
CREATE PROCEDURE sp_validate_code_mapping
    @source_code VARCHAR(50),
    @source_system VARCHAR(50),
    @target_system VARCHAR(50)
AS
BEGIN
    SELECT 
        CASE 
            WHEN EXISTS (
                SELECT 1
                FROM tbl_node n1
                JOIN tbl_closure c1 ON n1.node_id = c1.descendant_id
                JOIN tbl_closure c2 ON c1.ancestor_id = c2.ancestor_id
                JOIN tbl_node n2 ON c2.descendant_id = n2.node_id
                WHERE n1.code = @source_code
                AND n1.source_system = @source_system
                AND n2.source_system = @target_system
            ) THEN 1
            ELSE 0
        END as has_mapping;
END;
```

### 4. Code Migration
```sql
-- Migrate codes from one system to another
CREATE PROCEDURE sp_migrate_codes
    @source_system VARCHAR(50),
    @target_system VARCHAR(50)
AS
BEGIN
    SELECT 
        n1.code as source_code,
        n2.code as target_code,
        n1.description as source_description,
        n2.description as target_description
    FROM tbl_node n1
    JOIN tbl_closure c1 ON n1.node_id = c1.descendant_id
    JOIN tbl_closure c2 ON c1.ancestor_id = c2.ancestor_id
    JOIN tbl_node n2 ON c2.descendant_id = n2.node_id
    WHERE n1.source_system = @source_system
    AND n2.source_system = @target_system;
END;
```

### 5. Impact Analysis
```sql
-- Analyze impact of code changes
CREATE PROCEDURE sp_analyze_code_impact
    @code VARCHAR(50),
    @source_system VARCHAR(50)
AS
BEGIN
    -- Find all dependent codes
    SELECT 
        n2.code,
        n2.source_system,
        n2.description
    FROM tbl_node n1
    JOIN tbl_closure c ON n1.node_id = c.ancestor_id
    JOIN tbl_node n2 ON c.descendant_id = n2.node_id
    WHERE n1.code = @code
    AND n1.source_system = @source_system
    AND n2.node_id != n1.node_id;
    
    -- Find all parent codes
    SELECT 
        n2.code,
        n2.source_system,
        n2.description
    FROM tbl_node n1
    JOIN tbl_closure c ON n1.node_id = c.descendant_id
    JOIN tbl_node n2 ON c.ancestor_id = n2.node_id
    WHERE n1.code = @code
    AND n1.source_system = @source_system
    AND n2.node_id != n1.node_id;
END;
```

### 6. Reporting
```sql
-- Generate mapping coverage report
CREATE PROCEDURE sp_mapping_coverage_report
AS
BEGIN
    WITH CodeSystems AS (
        SELECT DISTINCT source_system
        FROM tbl_node
    ),
    MappingCounts AS (
        SELECT 
            n1.source_system,
            COUNT(DISTINCT n2.source_system) as mapped_systems,
            COUNT(DISTINCT n1.code) as total_codes
        FROM tbl_node n1
        LEFT JOIN tbl_closure c1 ON n1.node_id = c1.descendant_id
        LEFT JOIN tbl_closure c2 ON c1.ancestor_id = c2.ancestor_id
        LEFT JOIN tbl_node n2 ON c2.descendant_id = n2.node_id
        WHERE n2.source_system != n1.source_system
        GROUP BY n1.source_system
    )
    SELECT 
        m.source_system,
        m.total_codes,
        m.mapped_systems,
        CAST(m.mapped_systems AS FLOAT) / 
            (SELECT COUNT(*) FROM CodeSystems) * 100 as coverage_percentage
    FROM MappingCounts m;
END;
```

## Best Practices

1. **Code Mapping**
   - Always validate source and target systems
   - Maintain mapping history
   - Document mapping rules

2. **Data Quality**
   - Regular validation of hierarchies
   - Check for circular references
   - Maintain code descriptions

3. **Performance**
   - Use appropriate indexes
   - Batch process large updates
   - Monitor query performance

4. **Maintenance**
   - Regular cleanup of obsolete codes
   - Update statistics
   - Archive historical data

## Common Pitfalls

1. **Circular References**
   - Always validate hierarchy before insertion
   - Implement checks in sp_add_node

2. **Missing Mappings**
   - Regular validation of mapping coverage
   - Alert on unmapped codes

3. **Performance Issues**
   - Avoid deep recursive queries
   - Use closure table efficiently
   - Monitor query patterns
