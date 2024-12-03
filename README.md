# Healthcare Type Code Hierarchy Management System

## Project Overview
A sophisticated SQL-based solution for managing hierarchical healthcare type codes using graph database concepts. The system implements a closure table pattern to efficiently handle complex hierarchical relationships between different coding systems and data sources.

## Core Features
- Hierarchical type code management using closure tables
- Efficient querying of type code relationships
- Flexible mapping between different coding systems
- Standardized views for code extraction
- Support for multiple healthcare data sources

## Technical Architecture

### Database Schema
1. Core Tables:
   - `tbl_node`: Stores individual type codes and their metadata
   - `tbl_closure`: Manages hierarchical relationships using closure table pattern

2. Views:
   - Multiple specialized views for different code extraction scenarios
   - Hierarchical relationship querying
   - Cross-system code mapping

### Implementation Details
```sql
-- Core Table Structure
CREATE TABLE tbl_node (
    node_id INT PRIMARY KEY,
    code VARCHAR(50),
    description TEXT,
    source_system VARCHAR(50),
    valid_from DATE,
    valid_to DATE,
    -- Additional metadata fields
);

CREATE TABLE tbl_closure (
    ancestor_id INT,
    descendant_id INT,
    path_length INT,
    FOREIGN KEY (ancestor_id) REFERENCES tbl_node(node_id),
    FOREIGN KEY (descendant_id) REFERENCES tbl_node(node_id),
    PRIMARY KEY (ancestor_id, descendant_id)
);
```

## Benefits
1. **Efficient Querying**:
   - Fast hierarchical data retrieval
   - Optimized ancestor/descendant searches
   - Flexible relationship mapping

2. **Data Integrity**:
   - Maintains relationships between different coding systems
   - Ensures data consistency
   - Supports historical tracking

3. **Scalability**:
   - Handles multiple coding systems
   - Supports growing hierarchies
   - Efficient for large datasets

## Use Cases
1. Code Mapping:
   - Map codes between different systems
   - Track code relationships
   - Maintain version history

2. Data Integration:
   - Standardize codes across systems
   - Support ETL processes
   - Enable consistent reporting

3. Analysis:
   - Hierarchy analysis
   - Impact assessment
   - Relationship tracking

## Technical Stack
- SQL Server
- Graph Database Concepts
- Closure Table Pattern
- SQL Views
- Stored Procedures

## Getting Started
1. Database Setup
2. Initial Data Migration
3. View Creation
4. Testing Queries

## Documentation
Detailed documentation including:
- Schema design
- Implementation details
- Query patterns
- Best practices
- Performance considerations
