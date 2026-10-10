-- ============================================================
-- ALTER Payments Table - Add MemberId, TransactionId, Status
-- ============================================================

USE GymDb;
GO

PRINT 'Altering Payments table...';

-- Check if columns already exist before adding
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'MemberId')
BEGIN
    ALTER TABLE Payments ADD MemberId INT NOT NULL DEFAULT 0;
    ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId);
    PRINT '✓ Added MemberId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'TransactionId')
BEGIN
    ALTER TABLE Payments ADD TransactionId NVARCHAR(100) NULL;
    PRINT '✓ Added TransactionId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'Status')
BEGIN
    ALTER TABLE Payments ADD Status NVARCHAR(20) NOT NULL DEFAULT 'Completed' CHECK (Status IN ('Completed','Pending','Failed'));
    PRINT '✓ Added Status column';
END

-- Make InvoiceId nullable (for direct payments without invoice)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'InvoiceId' AND is_nullable = 0)
BEGIN
    -- Drop FK constraint first
    DECLARE @ConstraintName NVARCHAR(200);
    SELECT @ConstraintName = name 
    FROM sys.foreign_keys 
    WHERE parent_object_id = OBJECT_ID('Payments') 
    AND referenced_object_id = OBJECT_ID('Invoices');
    
    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE Payments DROP CONSTRAINT ' + @ConstraintName);
        PRINT '✓ Dropped old FK constraint on InvoiceId';
    END
    
    -- Alter column to nullable
    ALTER TABLE Payments ALTER COLUMN InvoiceId INT NULL;
    PRINT '✓ Made InvoiceId nullable';
    
    -- Re-add FK constraint
    ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Invoices FOREIGN KEY (InvoiceId) REFERENCES Invoices(InvoiceId);
    PRINT '✓ Re-added FK constraint on InvoiceId';
END

-- Add index on MemberId
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Payments_MemberId')
BEGIN
    CREATE INDEX IX_Payments_MemberId ON Payments(MemberId);
    PRINT '✓ Added index on MemberId';
END

PRINT '✅ Payments table altered successfully!';
GO
