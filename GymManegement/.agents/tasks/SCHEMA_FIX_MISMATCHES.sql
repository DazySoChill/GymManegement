-- ============================================================
-- SCHEMA FIX: Backend-Database Mapping Mismatches
-- ============================================================
-- Database: GymDb
-- Generated: 2024
-- Purpose: Fix mismatches between C# entities and database schema
-- ============================================================

USE GymDb;
GO

PRINT '========================================';
PRINT 'Starting Schema Fix for Mismatches';
PRINT '========================================';
PRINT '';

-- ============================================================
-- FIX 1: Standardize UpdatedAt columns to nullable datetime
-- ============================================================
PRINT 'FIX 1: Standardizing UpdatedAt columns to nullable...';

-- Users.UpdatedAt: Change from datetime NOT NULL to datetime NULL
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Users' 
    AND COLUMN_NAME = 'UpdatedAt' 
    AND IS_NULLABLE = 'NO'
)
BEGIN
    PRINT '  - Altering Users.UpdatedAt to nullable datetime';
    ALTER TABLE Users
    ALTER COLUMN UpdatedAt datetime NULL;
    PRINT '    ✓ Users.UpdatedAt is now nullable';
END
ELSE
BEGIN
    PRINT '    ℹ Users.UpdatedAt is already nullable';
END
GO

-- Payments.UpdatedAt: Change from datetime NOT NULL to datetime NULL
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Payments' 
    AND COLUMN_NAME = 'UpdatedAt' 
    AND IS_NULLABLE = 'NO'
)
BEGIN
    PRINT '  - Altering Payments.UpdatedAt to nullable datetime';
    ALTER TABLE Payments
    ALTER COLUMN UpdatedAt datetime NULL;
    PRINT '    ✓ Payments.UpdatedAt is now nullable';
END
ELSE
BEGIN
    PRINT '    ℹ Payments.UpdatedAt is already nullable';
END
GO

-- ============================================================
-- FIX 2: Standardize Invoices.UpdatedAt to datetime (from datetime2)
-- ============================================================
PRINT '';
PRINT 'FIX 2: Standardizing Invoices.UpdatedAt to datetime...';

IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Invoices' 
    AND COLUMN_NAME = 'UpdatedAt' 
    AND DATA_TYPE = 'datetime2'
)
BEGIN
    PRINT '  - Altering Invoices.UpdatedAt from datetime2 to datetime';
    ALTER TABLE Invoices
    ALTER COLUMN UpdatedAt datetime NULL;
    PRINT '    ✓ Invoices.UpdatedAt is now datetime (nullable)';
END
ELSE
BEGIN
    PRINT '    ℹ Invoices.UpdatedAt is already datetime';
END
GO

-- ============================================================
-- FIX 3: Create AuditLogs table (if needed)
-- ============================================================
PRINT '';
PRINT 'FIX 3: Creating AuditLogs table if it does not exist...';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AuditLogs')
BEGIN
    PRINT '  - Creating AuditLogs table';
    
    CREATE TABLE AuditLogs (
        AuditLogId INT IDENTITY(1,1) PRIMARY KEY,
        TableName NVARCHAR(100) NOT NULL,
        RecordId INT NOT NULL,
        [Action] NVARCHAR(50) NOT NULL,  -- INSERT, UPDATE, DELETE
        UserId INT NULL,
        Username NVARCHAR(100) NULL,
        OldValues NVARCHAR(MAX) NULL,
        NewValues NVARCHAR(MAX) NULL,
        ChangedAt DATETIME NOT NULL DEFAULT GETDATE(),
        IpAddress NVARCHAR(50) NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        DeletedAt DATETIME NULL
    );
    
    PRINT '    ✓ AuditLogs table created';
    
    -- Create index for efficient querying
    CREATE INDEX IX_AuditLogs_TableRecord ON AuditLogs(TableName, RecordId);
    CREATE INDEX IX_AuditLogs_ChangedAt ON AuditLogs(ChangedAt DESC);
    
    PRINT '    ✓ Indexes created on AuditLogs';
END
ELSE
BEGIN
    PRINT '    ℹ AuditLogs table already exists';
END
GO

-- ============================================================
-- FIX 4: Create stored procedures for AuditLog
-- ============================================================
PRINT '';
PRINT 'FIX 4: Creating AuditLog stored procedures...';

-- sp_AuditLog_Create
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'sp_AuditLog_Create')
BEGIN
    DROP PROCEDURE sp_AuditLog_Create;
    PRINT '  - Dropped existing sp_AuditLog_Create';
END
GO

CREATE PROCEDURE sp_AuditLog_Create
    @TableName NVARCHAR(100),
    @RecordId INT,
    @Action NVARCHAR(50),
    @UserId INT = NULL,
    @Username NVARCHAR(100) = NULL,
    @OldValues NVARCHAR(MAX) = NULL,
    @NewValues NVARCHAR(MAX) = NULL,
    @IpAddress NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLogs (TableName, RecordId, [Action], UserId, Username, OldValues, NewValues, IpAddress, ChangedAt, CreatedAt, IsDeleted)
    VALUES (@TableName, @RecordId, @Action, @UserId, @Username, @OldValues, @NewValues, @IpAddress, GETDATE(), GETDATE(), 0);
    
    RETURN SCOPE_IDENTITY();
END
GO

PRINT '    ✓ sp_AuditLog_Create created';
GO

-- sp_AuditLog_GetByRecord
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'sp_AuditLog_GetByRecord')
BEGIN
    DROP PROCEDURE sp_AuditLog_GetByRecord;
    PRINT '  - Dropped existing sp_AuditLog_GetByRecord';
END
GO

CREATE PROCEDURE sp_AuditLog_GetByRecord
    @TableName NVARCHAR(100),
    @RecordId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        AuditLogId,
        TableName,
        RecordId,
        [Action],
        UserId,
        Username,
        OldValues,
        NewValues,
        ChangedAt,
        IpAddress,
        CreatedAt,
        UpdatedAt,
        IsDeleted,
        DeletedAt
    FROM AuditLogs
    WHERE TableName = @TableName 
      AND RecordId = @RecordId
      AND IsDeleted = 0
    ORDER BY ChangedAt DESC;
END
GO

PRINT '    ✓ sp_AuditLog_GetByRecord created';
GO

-- ============================================================
-- VERIFICATION: Check all fixes applied
-- ============================================================
PRINT '';
PRINT '========================================';
PRINT 'VERIFICATION: Checking applied fixes';
PRINT '========================================';
PRINT '';

-- Check Users.UpdatedAt
SELECT 
    'Users.UpdatedAt' AS ColumnCheck,
    CASE WHEN IS_NULLABLE = 'YES' THEN '✓ Nullable' ELSE '✗ NOT NULL' END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'UpdatedAt';

-- Check Payments.UpdatedAt
SELECT 
    'Payments.UpdatedAt' AS ColumnCheck,
    CASE WHEN IS_NULLABLE = 'YES' THEN '✓ Nullable' ELSE '✗ NOT NULL' END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Payments' AND COLUMN_NAME = 'UpdatedAt';

-- Check Invoices.UpdatedAt
SELECT 
    'Invoices.UpdatedAt' AS ColumnCheck,
    DATA_TYPE AS CurrentType,
    CASE WHEN DATA_TYPE = 'datetime' THEN '✓ datetime' ELSE '⚠ ' + DATA_TYPE END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Invoices' AND COLUMN_NAME = 'UpdatedAt';

-- Check AuditLogs table
SELECT 
    'AuditLogs Table' AS TableCheck,
    CASE WHEN COUNT(*) > 0 THEN '✓ Exists' ELSE '✗ Missing' END AS Status
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'AuditLogs';

-- Check stored procedures
SELECT 
    'sp_AuditLog_Create' AS ProcedureCheck,
    CASE WHEN COUNT(*) > 0 THEN '✓ Exists' ELSE '✗ Missing' END AS Status
FROM sys.objects
WHERE type = 'P' AND name = 'sp_AuditLog_Create';

SELECT 
    'sp_AuditLog_GetByRecord' AS ProcedureCheck,
    CASE WHEN COUNT(*) > 0 THEN '✓ Exists' ELSE '✗ Missing' END AS Status
FROM sys.objects
WHERE type = 'P' AND name = 'sp_AuditLog_GetByRecord';

PRINT '';
PRINT '========================================';
PRINT 'Schema Fix Completed Successfully';
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '  ✓ UpdatedAt columns standardized to nullable datetime';
PRINT '  ✓ Invoices.UpdatedAt changed to datetime';
PRINT '  ✓ AuditLogs table created';
PRINT '  ✓ AuditLog stored procedures created';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Add MemberId property to User.cs entity (int? MemberId { get; set; })';
PRINT '  2. Run dotnet build to verify compilation';
PRINT '  3. Test existing functionality to ensure no regressions';
PRINT '';
