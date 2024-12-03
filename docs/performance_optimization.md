# Performance Optimization Guide for Healthcare Type Code Hierarchy

## Database Design Optimizations

### 1. Indexing Strategy
```sql
-- Core table indexes
CREATE INDEX IX_node_code ON tbl_node(code);
CREATE INDEX IX_node_system ON tbl_node(source_system);
CREATE INDEX IX_node_composite ON tbl_node(code, source_system, code_type);

-- Closure table indexes
CREATE INDEX IX_closure_ancestor ON tbl_closure(ancestor_id);
CREATE INDEX IX_closure_descendant ON tbl_closure(descendant_id);
CREATE INDEX IX_closure_path ON tbl_closure(path_length);
```

### 2. Table Partitioning
For large installations (>1M codes):
```sql
-- Partition by source system
CREATE PARTITION FUNCTION PF_SourceSystem (VARCHAR(50))
AS RANGE RIGHT FOR VALUES ('ICD10', 'SNOMED', 'LOCAL');

-- Apply partitioning
ALTER TABLE tbl_node
ADD CONSTRAINT PK_node PRIMARY KEY NONCLUSTERED (node_id)
ON [PRIMARY];
```

## Query Optimization Techniques

### 1. Efficient Ancestor Queries
```sql
-- Instead of recursive CTE, use closure table
SELECT DISTINCT n.*
FROM tbl_node n
JOIN tbl_closure c ON n.node_id = c.ancestor_id
WHERE c.descendant_id = @node_id
AND c.path_length > 0;
```

### 2. Batch Processing
```sql
-- For bulk inserts
CREATE PROCEDURE sp_bulk_add_nodes
    @NodeTable TypeNodeTable READONLY
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Insert nodes in batch
    INSERT INTO tbl_node (code, description, source_system)
    SELECT code, description, source_system
    FROM @NodeTable;
    
    -- Update closure table in batch
    INSERT INTO tbl_closure (ancestor_id, descendant_id, path_length)
    SELECT n.node_id, n.node_id, 0
    FROM @NodeTable t
    JOIN tbl_node n ON t.code = n.code;
END;
```

### 3. Materialized Views
For frequently accessed hierarchies:
```sql
CREATE VIEW vw_common_hierarchies
WITH SCHEMABINDING
AS
SELECT 
    n1.code as parent_code,
    n1.source_system as parent_system,
    n2.code as child_code,
    n2.source_system as child_system,
    c.path_length
FROM dbo.tbl_closure c
JOIN dbo.tbl_node n1 ON c.ancestor_id = n1.node_id
JOIN dbo.tbl_node n2 ON c.descendant_id = n2.node_id
WHERE c.path_length = 1;

CREATE UNIQUE CLUSTERED INDEX IX_common_hierarchies
ON vw_common_hierarchies(parent_code, child_code);
```

## Maintenance Procedures

### 1. Statistics Update
```sql
CREATE PROCEDURE sp_update_hierarchy_stats
AS
BEGIN
    UPDATE STATISTICS tbl_node WITH FULLSCAN;
    UPDATE STATISTICS tbl_closure WITH FULLSCAN;
END;
```

### 2. Index Maintenance
```sql
CREATE PROCEDURE sp_rebuild_hierarchy_indexes
AS
BEGIN
    ALTER INDEX ALL ON tbl_node REBUILD;
    ALTER INDEX ALL ON tbl_closure REBUILD;
END;
```

## Monitoring Queries

### 1. Performance Monitoring
```sql
-- Check index usage
SELECT 
    OBJECT_NAME(i.object_id) as TableName,
    i.name as IndexName,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates
FROM sys.dm_db_index_usage_stats ius
JOIN sys.indexes i ON ius.object_id = i.object_id
WHERE ius.database_id = DB_ID()
AND OBJECT_NAME(i.object_id) IN ('tbl_node', 'tbl_closure');

-- Check query performance
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count as avg_elapsed_time,
    qs.total_logical_reads / qs.execution_count as avg_logical_reads,
    qs.execution_count,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
            END - qs.statement_start_offset)/2) + 1) as query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.text LIKE '%tbl_node%' OR qt.text LIKE '%tbl_closure%'
ORDER BY avg_elapsed_time DESC;
```

## Best Practices

1. **Batch Operations**
   - Use table-valued parameters for bulk operations
   - Implement batch processing for large data sets
   - Use transaction management for consistency

2. **Query Optimization**
   - Use appropriate indexes
   - Avoid recursive CTEs when possible
   - Implement materialized views for common queries

3. **Maintenance**
   - Regular statistics updates
   - Index maintenance
   - Performance monitoring

4. **Memory Optimization**
   - Use appropriate data types
   - Implement table partitioning for large datasets
   - Consider columnstore indexes for reporting

## Scaling Considerations

1. **Horizontal Scaling**
   - Implement read replicas
   - Consider data sharding for very large installations
   - Use caching for frequent lookups

2. **Vertical Scaling**
   - Optimize memory usage
   - Tune SQL Server configuration
   - Monitor resource usage
