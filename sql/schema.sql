-- Core Tables
CREATE TABLE tbl_node (
    node_id INT IDENTITY(1,1) PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    description NVARCHAR(MAX),
    source_system VARCHAR(50) NOT NULL,
    code_type VARCHAR(50) NOT NULL,
    valid_from DATE NOT NULL DEFAULT GETDATE(),
    valid_to DATE,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NOT NULL DEFAULT GETDATE(),
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT UQ_node_code_system UNIQUE (code, source_system)
);

CREATE TABLE tbl_closure (
    ancestor_id INT NOT NULL,
    descendant_id INT NOT NULL,
    path_length INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_closure PRIMARY KEY (ancestor_id, descendant_id),
    CONSTRAINT FK_closure_ancestor FOREIGN KEY (ancestor_id) REFERENCES tbl_node(node_id),
    CONSTRAINT FK_closure_descendant FOREIGN KEY (descendant_id) REFERENCES tbl_node(node_id)
);

-- Indexes for performance
CREATE INDEX IX_node_code ON tbl_node(code);
CREATE INDEX IX_node_system ON tbl_node(source_system);
CREATE INDEX IX_closure_ancestor ON tbl_closure(ancestor_id);
CREATE INDEX IX_closure_descendant ON tbl_closure(descendant_id);
CREATE INDEX IX_closure_path ON tbl_closure(path_length);

-- Views for different hierarchical queries
CREATE VIEW vw_direct_relationships AS
SELECT 
    n1.code as parent_code,
    n1.source_system as parent_system,
    n2.code as child_code,
    n2.source_system as child_system
FROM tbl_closure c
JOIN tbl_node n1 ON c.ancestor_id = n1.node_id
JOIN tbl_node n2 ON c.descendant_id = n2.node_id
WHERE c.path_length = 1;

CREATE VIEW vw_all_relationships AS
SELECT 
    n1.code as ancestor_code,
    n1.source_system as ancestor_system,
    n2.code as descendant_code,
    n2.source_system as descendant_system,
    c.path_length
FROM tbl_closure c
JOIN tbl_node n1 ON c.ancestor_id = n1.node_id
JOIN tbl_node n2 ON c.descendant_id = n2.node_id;

-- Helper stored procedures
CREATE PROCEDURE sp_add_node
    @code VARCHAR(50),
    @description NVARCHAR(MAX),
    @source_system VARCHAR(50),
    @code_type VARCHAR(50),
    @parent_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @node_id INT;
    
    -- Insert the new node
    INSERT INTO tbl_node (code, description, source_system, code_type)
    VALUES (@code, @description, @source_system, @code_type);
    
    SET @node_id = SCOPE_IDENTITY();
    
    -- Insert self-reference in closure table
    INSERT INTO tbl_closure (ancestor_id, descendant_id, path_length)
    VALUES (@node_id, @node_id, 0);
    
    -- If parent exists, create relationships
    IF @parent_id IS NOT NULL
    BEGIN
        INSERT INTO tbl_closure (ancestor_id, descendant_id, path_length)
        SELECT ancestor_id, @node_id, path_length + 1
        FROM tbl_closure
        WHERE descendant_id = @parent_id;
    END
END;

-- Function to get all ancestors
CREATE FUNCTION fn_get_ancestors
(
    @node_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        n.node_id,
        n.code,
        n.source_system,
        c.path_length
    FROM tbl_closure c
    JOIN tbl_node n ON c.ancestor_id = n.node_id
    WHERE c.descendant_id = @node_id
    AND c.path_length > 0
);

-- Function to get all descendants
CREATE FUNCTION fn_get_descendants
(
    @node_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        n.node_id,
        n.code,
        n.source_system,
        c.path_length
    FROM tbl_closure c
    JOIN tbl_node n ON c.descendant_id = n.node_id
    WHERE c.ancestor_id = @node_id
    AND c.path_length > 0
);
