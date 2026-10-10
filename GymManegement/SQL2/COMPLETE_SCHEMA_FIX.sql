-- ============================================================
-- COMPLETE_SCHEMA_FIX.sql
-- Comprehensive schema fix for GymDb database
-- ============================================================

USE GymDb;
GO

PRINT '========================================';
PRINT 'Starting Complete Schema Fix...';
PRINT '========================================';
GO

-- ============================================================
-- 1. FIX MEMBERSHIPS TABLE
-- ============================================================
PRINT 'Fixing Memberships table...';

-- Add PackageName column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Memberships') AND name = 'PackageName')
BEGIN
    ALTER TABLE Memberships ADD PackageName NVARCHAR(100) NOT NULL DEFAULT '';
    PRINT '✓ Added PackageName column';
END

-- Copy data from MembershipType to PackageName if MembershipType exists
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Memberships') AND name = 'MembershipType')
BEGIN
    UPDATE Memberships 
    SET PackageName = MembershipType 
    WHERE PackageName = '' OR PackageName IS NULL;
    PRINT '✓ Copied MembershipType to PackageName';
END

-- Remove Status column if exists (not in C# entity)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Memberships') AND name = 'Status')
BEGIN
    -- Drop CHECK constraint first
    DECLARE @StatusConstraint NVARCHAR(200);
    SELECT @StatusConstraint = name 
    FROM sys.check_constraints 
    WHERE parent_object_id = OBJECT_ID('Memberships') 
    AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Memberships') AND name = 'Status');
    
    IF @StatusConstraint IS NOT NULL
        EXEC('ALTER TABLE Memberships DROP CONSTRAINT ' + @StatusConstraint);
    
    ALTER TABLE Memberships DROP COLUMN Status;
    PRINT '✓ Removed Status column (not in C# entity)';
END

PRINT '✅ Memberships table fixed';
GO

-- ============================================================
-- 2. FIX INVOICES TABLE
-- ============================================================
PRINT 'Fixing Invoices table...';

-- Ensure MemberId column exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'MemberId')
BEGIN
    ALTER TABLE Invoices ADD MemberId INT NOT NULL DEFAULT 0;
    
    -- Add FK constraint
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Invoices_Members')
        ALTER TABLE Invoices ADD CONSTRAINT FK_Invoices_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId);
    
    PRINT '✓ Added MemberId column with FK';
END

-- Make MembershipId nullable
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'MembershipId' AND is_nullable = 0)
BEGIN
    -- Drop FK constraint first
    DECLARE @InvoiceMembershipFK NVARCHAR(200);
    SELECT @InvoiceMembershipFK = name 
    FROM sys.foreign_keys 
    WHERE parent_object_id = OBJECT_ID('Invoices') 
    AND referenced_object_id = OBJECT_ID('Memberships');
    
    IF @InvoiceMembershipFK IS NOT NULL
        EXEC('ALTER TABLE Invoices DROP CONSTRAINT ' + @InvoiceMembershipFK);
    
    ALTER TABLE Invoices ALTER COLUMN MembershipId INT NULL;
    
    -- Re-add FK constraint
    ALTER TABLE Invoices ADD CONSTRAINT FK_Invoices_Memberships FOREIGN KEY (MembershipId) REFERENCES Memberships(MembershipId);
    PRINT '✓ Made MembershipId nullable';
END

-- Make DueDate nullable
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'DueDate' AND is_nullable = 0)
BEGIN
    -- Drop DEFAULT constraint if exists
    DECLARE @DueDateDefault NVARCHAR(200);
    SELECT @DueDateDefault = name 
    FROM sys.default_constraints 
    WHERE parent_object_id = OBJECT_ID('Invoices') 
    AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'DueDate');
    
    IF @DueDateDefault IS NOT NULL
        EXEC('ALTER TABLE Invoices DROP CONSTRAINT ' + @DueDateDefault);
    
    ALTER TABLE Invoices ALTER COLUMN DueDate DATE NULL;
    PRINT '✓ Made DueDate nullable';
END

-- Make UpdatedAt nullable
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'UpdatedAt' AND is_nullable = 0)
BEGIN
    -- Drop DEFAULT constraint if exists
    DECLARE @UpdatedAtDefault NVARCHAR(200);
    SELECT @UpdatedAtDefault = name 
    FROM sys.default_constraints 
    WHERE parent_object_id = OBJECT_ID('Invoices') 
    AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'UpdatedAt');
    
    IF @UpdatedAtDefault IS NOT NULL
        EXEC('ALTER TABLE Invoices DROP CONSTRAINT ' + @UpdatedAtDefault);
    
    ALTER TABLE Invoices ALTER COLUMN UpdatedAt DATETIME2 NULL;
    PRINT '✓ Made UpdatedAt nullable';
END

-- Rename Amount to TotalAmount if needed
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'Amount')
AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'TotalAmount')
BEGIN
    EXEC sp_rename 'Invoices.Amount', 'TotalAmount', 'COLUMN';
    PRINT '✓ Renamed Amount to TotalAmount';
END

-- Rename IssueDate to InvoiceDate if needed
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'IssueDate')
AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'InvoiceDate')
BEGIN
    EXEC sp_rename 'Invoices.IssueDate', 'InvoiceDate', 'COLUMN';
    PRINT '✓ Renamed IssueDate to InvoiceDate';
END

PRINT '✅ Invoices table fixed';
GO

-- ============================================================
-- 3. FIX PAYMENTS TABLE (run ALTER_PAYMENTS_TABLE.sql logic)
-- ============================================================
PRINT 'Fixing Payments table...';

-- Add MemberId column (nullable to avoid FK violations on existing data)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'MemberId')
BEGIN
    ALTER TABLE Payments ADD MemberId INT NULL;
    
    -- Backfill MemberId from Invoices for existing payments
    UPDATE Payments 
    SET MemberId = (SELECT TOP 1 MemberId FROM Invoices WHERE Invoices.InvoiceId = Payments.InvoiceId)
    WHERE InvoiceId IS NOT NULL AND MemberId IS NULL;
    
    -- Now make it NOT NULL
    ALTER TABLE Payments ALTER COLUMN MemberId INT NOT NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Payments_Members')
        ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId);
    
    PRINT '✓ Added MemberId column with backfill';
END

-- Add TransactionId column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'TransactionId')
BEGIN
    ALTER TABLE Payments ADD TransactionId NVARCHAR(100) NULL;
    PRINT '✓ Added TransactionId column';
END

-- Add Status column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'Status')
BEGIN
    ALTER TABLE Payments ADD Status NVARCHAR(20) NOT NULL DEFAULT 'Completed' CHECK (Status IN ('Completed','Pending','Failed'));
    PRINT '✓ Added Status column';
END

-- Make InvoiceId nullable
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'InvoiceId' AND is_nullable = 0)
BEGIN
    -- Drop FK constraint first
    DECLARE @PaymentInvoiceFK NVARCHAR(200);
    SELECT @PaymentInvoiceFK = name 
    FROM sys.foreign_keys 
    WHERE parent_object_id = OBJECT_ID('Payments') 
    AND referenced_object_id = OBJECT_ID('Invoices');
    
    IF @PaymentInvoiceFK IS NOT NULL
        EXEC('ALTER TABLE Payments DROP CONSTRAINT ' + @PaymentInvoiceFK);
    
    ALTER TABLE Payments ALTER COLUMN InvoiceId INT NULL;
    
    -- Re-add FK constraint
    ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Invoices FOREIGN KEY (InvoiceId) REFERENCES Invoices(InvoiceId);
    PRINT '✓ Made InvoiceId nullable';
END

-- Add index on MemberId
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Payments_MemberId' AND object_id = OBJECT_ID('Payments'))
BEGIN
    CREATE INDEX IX_Payments_MemberId ON Payments(MemberId);
    PRINT '✓ Added index on MemberId';
END

PRINT '✅ Payments table fixed';
GO

-- ============================================================
-- 4. FIX SCHEDULES TABLE
-- ============================================================
PRINT 'Fixing Schedules table...';

-- REMOVE MemberId column (Schedules are class schedules, not personal)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Schedules') AND name = 'MemberId')
BEGIN
    -- Drop FK constraint first
    DECLARE @ScheduleMemberFK NVARCHAR(200);
    SELECT @ScheduleMemberFK = name 
    FROM sys.foreign_keys 
    WHERE parent_object_id = OBJECT_ID('Schedules') 
    AND referenced_object_id = OBJECT_ID('Members');
    
    IF @ScheduleMemberFK IS NOT NULL
        EXEC('ALTER TABLE Schedules DROP CONSTRAINT ' + @ScheduleMemberFK);
    
    -- Drop index if exists
    IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Schedules_MemberId' AND object_id = OBJECT_ID('Schedules'))
        DROP INDEX IX_Schedules_MemberId ON Schedules;
    
    ALTER TABLE Schedules DROP COLUMN MemberId;
    PRINT '✓ Removed MemberId column';
END

-- Add ClassName column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Schedules') AND name = 'ClassName')
BEGIN
    ALTER TABLE Schedules ADD ClassName NVARCHAR(100) NOT NULL DEFAULT 'Class';
    PRINT '✓ Added ClassName column';
END

-- Add MaxCapacity column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Schedules') AND name = 'MaxCapacity')
BEGIN
    ALTER TABLE Schedules ADD MaxCapacity INT NOT NULL DEFAULT 20;
    PRINT '✓ Added MaxCapacity column';
END

-- Change ScheduledDate + StartTime/EndTime (DATE+TIME) to StartTime/EndTime (DATETIME2)
-- This is complex, so we'll keep both for now and populate datetime versions
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Schedules') AND name = 'ScheduledDate')
AND EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Schedules') AND name = 'StartTime')
AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Schedules') AND name = 'StartDateTime')
BEGIN
    -- Check if StartTime is TIME type (not DATETIME2)
    DECLARE @StartTimeType NVARCHAR(128);
    SELECT @StartTimeType = TYPE_NAME(system_type_id)
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('Schedules') AND name = 'StartTime';
    
    IF @StartTimeType = 'time'
    BEGIN
        -- Create temp datetime columns
        ALTER TABLE Schedules ADD StartDateTime DATETIME2 NULL;
        ALTER TABLE Schedules ADD EndDateTime DATETIME2 NULL;
        
        -- Combine ScheduledDate + StartTime/EndTime into datetime columns
        UPDATE Schedules 
        SET StartDateTime = CAST(CAST(ScheduledDate AS DATETIME) + CAST(StartTime AS DATETIME) AS DATETIME2),
            EndDateTime = CAST(CAST(ScheduledDate AS DATETIME) + CAST(EndTime AS DATETIME) AS DATETIME2);
        
        -- Drop old columns
        ALTER TABLE Schedules DROP COLUMN ScheduledDate;
        ALTER TABLE Schedules DROP COLUMN StartTime;
        ALTER TABLE Schedules DROP COLUMN EndTime;
        
        -- Rename temp columns
        EXEC sp_rename 'Schedules.StartDateTime', 'StartTime', 'COLUMN';
        EXEC sp_rename 'Schedules.EndDateTime', 'EndTime', 'COLUMN';
        
        -- Make non-nullable
        ALTER TABLE Schedules ALTER COLUMN StartTime DATETIME2 NOT NULL;
        ALTER TABLE Schedules ALTER COLUMN EndTime DATETIME2 NOT NULL;
        
        PRINT '✓ Converted ScheduledDate+TIME to DATETIME2';
    END
END

-- Remove Notes column if exists (not in C# entity)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Schedules') AND name = 'Notes')
BEGIN
    ALTER TABLE Schedules DROP COLUMN Notes;
    PRINT '✓ Removed Notes column';
END

PRINT '✅ Schedules table fixed';
GO

-- ============================================================
-- 5. FIX SESSIONS TABLE
-- ============================================================
PRINT 'Fixing Sessions table...';

-- Sessions should have: SessionId, ScheduleId, MemberId, RegistrationDate, Status
-- Remove ActualStartTime, ActualEndTime, Notes if they exist

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Sessions') AND name = 'ActualStartTime')
BEGIN
    ALTER TABLE Sessions DROP COLUMN ActualStartTime;
    PRINT '✓ Removed ActualStartTime column';
END

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Sessions') AND name = 'ActualEndTime')
BEGIN
    ALTER TABLE Sessions DROP COLUMN ActualEndTime;
    PRINT '✓ Removed ActualEndTime column';
END

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Sessions') AND name = 'Notes')
BEGIN
    ALTER TABLE Sessions DROP COLUMN Notes;
    PRINT '✓ Removed Notes column';
END

-- Add MemberId if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Sessions') AND name = 'MemberId')
BEGIN
    ALTER TABLE Sessions ADD MemberId INT NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Sessions_Members')
        ALTER TABLE Sessions ADD CONSTRAINT FK_Sessions_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId);
    
    PRINT '✓ Added MemberId column';
END

-- Add RegistrationDate if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Sessions') AND name = 'RegistrationDate')
BEGIN
    ALTER TABLE Sessions ADD RegistrationDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE);
    PRINT '✓ Added RegistrationDate column';
END

-- Add Status if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Sessions') AND name = 'Status')
BEGIN
    ALTER TABLE Sessions ADD Status NVARCHAR(20) NOT NULL DEFAULT 'Registered' CHECK (Status IN ('Registered','Attended','Cancelled','NoShow'));
    PRINT '✓ Added Status column';
END

PRINT '✅ Sessions table fixed';
GO

-- ============================================================
-- 6. FIX CHECKINS TABLE
-- ============================================================
PRINT 'Fixing Checkins table...';

-- Remove SessionId column (Checkins are gym entry, not class-specific)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Checkins') AND name = 'SessionId')
BEGIN
    -- Drop FK constraint first
    DECLARE @CheckinSessionFK NVARCHAR(200);
    SELECT @CheckinSessionFK = name 
    FROM sys.foreign_keys 
    WHERE parent_object_id = OBJECT_ID('Checkins') 
    AND referenced_object_id = OBJECT_ID('Sessions');
    
    IF @CheckinSessionFK IS NOT NULL
        EXEC('ALTER TABLE Checkins DROP CONSTRAINT ' + @CheckinSessionFK);
    
    -- Drop index if exists
    IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkins_SessionId' AND object_id = OBJECT_ID('Checkins'))
        DROP INDEX IX_Checkins_SessionId ON Checkins;
    
    ALTER TABLE Checkins DROP COLUMN SessionId;
    PRINT '✓ Removed SessionId column';
END

-- Remove CheckinMethod column
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Checkins') AND name = 'CheckinMethod')
BEGIN
    -- Drop CHECK constraint first
    DECLARE @CheckinMethodConstraint NVARCHAR(200);
    SELECT @CheckinMethodConstraint = name 
    FROM sys.check_constraints 
    WHERE parent_object_id = OBJECT_ID('Checkins') 
    AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Checkins') AND name = 'CheckinMethod');
    
    IF @CheckinMethodConstraint IS NOT NULL
        EXEC('ALTER TABLE Checkins DROP CONSTRAINT ' + @CheckinMethodConstraint);
    
    ALTER TABLE Checkins DROP COLUMN CheckinMethod;
    PRINT '✓ Removed CheckinMethod column';
END

-- Add CheckoutTime column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Checkins') AND name = 'CheckoutTime')
BEGIN
    ALTER TABLE Checkins ADD CheckoutTime DATETIME2 NULL;
    PRINT '✓ Added CheckoutTime column';
END

PRINT '✅ Checkins table fixed';
GO

-- ============================================================
-- 7. FIX USERS TABLE
-- ============================================================
PRINT 'Fixing Users table...';

-- Add LastLoginAt column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'LastLoginAt')
BEGIN
    ALTER TABLE Users ADD LastLoginAt DATETIME2 NULL;
    PRINT '✓ Added LastLoginAt column';
END

-- Add MemberId column if not exists (for linking Member users)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'MemberId')
BEGIN
    ALTER TABLE Users ADD MemberId INT NULL;
    PRINT '✓ Added MemberId column to Users';
END

-- Ensure Role includes SuperAdmin
DECLARE @RoleConstraint NVARCHAR(200);
SELECT @RoleConstraint = name 
FROM sys.check_constraints 
WHERE parent_object_id = OBJECT_ID('Users') 
AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'Role');

IF @RoleConstraint IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Users DROP CONSTRAINT ' + @RoleConstraint);
    ALTER TABLE Users ADD CONSTRAINT CK_Users_Role CHECK (Role IN ('SuperAdmin','Admin','Trainer','Member'));
    PRINT '✓ Updated Role constraint to include SuperAdmin';
END

PRINT '✅ Users table fixed';
GO

-- ============================================================
-- 8. FIX MEMBERS TABLE
-- ============================================================
PRINT 'Fixing Members table...';

-- Rename QRCodeValue to QRCode if needed
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Members') AND name = 'QRCodeValue')
AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Members') AND name = 'QRCode')
BEGIN
    EXEC sp_rename 'Members.QRCodeValue', 'QRCode', 'COLUMN';
    PRINT '✓ Renamed QRCodeValue to QRCode';
END

-- Remove Status column if exists (not in C# entity)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Members') AND name = 'Status')
BEGIN
    -- Drop CHECK constraint first
    DECLARE @MemberStatusConstraint NVARCHAR(200);
    SELECT @MemberStatusConstraint = name 
    FROM sys.check_constraints 
    WHERE parent_object_id = OBJECT_ID('Members') 
    AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Members') AND name = 'Status');
    
    IF @MemberStatusConstraint IS NOT NULL
        EXEC('ALTER TABLE Members DROP CONSTRAINT ' + @MemberStatusConstraint);
    
    -- Drop index if exists
    IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Members_Status' AND object_id = OBJECT_ID('Members'))
        DROP INDEX IX_Members_Status ON Members;
    
    ALTER TABLE Members DROP COLUMN Status;
    PRINT '✓ Removed Status column';
END

-- Remove JoinDate column if exists (not in C# entity)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Members') AND name = 'JoinDate')
BEGIN
    ALTER TABLE Members DROP COLUMN JoinDate;
    PRINT '✓ Removed JoinDate column';
END

PRINT '✅ Members table fixed';
GO

PRINT '========================================';
PRINT '✅ Complete Schema Fix Done!';
PRINT '========================================';
GO
