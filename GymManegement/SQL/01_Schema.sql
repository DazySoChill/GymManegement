-- ============================================================
-- FILE: 01_Schema.sql
-- Mô tả: Schema đầy đủ cho Gym Management (Phase 0)
-- Bao gồm: RBAC, Audit Log, Soft Delete, Versioning, Concurrency
-- Chạy thứ 1 (trước 04_Users.sql và 03_SeedData.sql)
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'GymDb')
    CREATE DATABASE GymDb;
GO

USE GymDb;
GO

-- ============================================================
-- 1. RBAC TABLES
-- ============================================================

-- Roles: Admin, Trainer, Member (IsSystem=1 là role hệ thống)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Roles' AND xtype='U')
CREATE TABLE Roles (
    RoleId          INT             IDENTITY(1,1) PRIMARY KEY,
    RoleName        NVARCHAR(50)    NOT NULL UNIQUE,      -- Admin, Trainer, Member
    Description     NVARCHAR(255)   NULL,
    IsSystem        BIT             NOT NULL DEFAULT 0,   -- 1 = role hệ thống, không cho xóa
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL
);
GO

-- Permissions: 35 quyền theo format Entity.Action
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Permissions' AND xtype='U')
CREATE TABLE Permissions (
    PermissionId    INT             IDENTITY(1,1) PRIMARY KEY,
    PermissionCode  NVARCHAR(100)   NOT NULL UNIQUE,      -- Members.Read, Members.Create, etc.
    Description     NVARCHAR(255)   NULL,
    Module          NVARCHAR(50)    NOT NULL,             -- Members, Memberships, Trainers, etc.
    Action          NVARCHAR(50)    NOT NULL              -- Read, Create, Update, Delete, Export
);
GO

-- RolePermissions: Many-to-Many mapping
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='RolePermissions' AND xtype='U')
CREATE TABLE RolePermissions (
    RoleId          INT             NOT NULL REFERENCES Roles(RoleId) ON DELETE CASCADE,
    PermissionId    INT             NOT NULL REFERENCES Permissions(PermissionId) ON DELETE CASCADE,
    PRIMARY KEY (RoleId, PermissionId)
);
GO

-- ============================================================
-- 2. CORE BUSINESS TABLES (with Audit + Soft Delete + Versioning)
-- ============================================================

-- Members (hội viên)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Members' AND xtype='U')
CREATE TABLE Members (
    MemberId        INT             IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Phone           NVARCHAR(20)    NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    DateOfBirth     DATE            NOT NULL,
    JoinDate        DATE            NOT NULL DEFAULT GETDATE(),
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active','Inactive','Suspended')),
    QRCodeValue     NVARCHAR(50)    NOT NULL UNIQUE,
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Members_IsDeleted' AND object_id = OBJECT_ID('Members'))
CREATE INDEX IX_Members_IsDeleted ON Members(IsDeleted);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Members_Email' AND object_id = OBJECT_ID('Members'))
BEGIN
    SET QUOTED_IDENTIFIER ON;
    CREATE INDEX IX_Members_Email ON Members(Email) WHERE IsDeleted = 0;
END
GO

-- Trainers (huấn luyện viên)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Trainers' AND xtype='U')
CREATE TABLE Trainers (
    TrainerId       INT             IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Phone           NVARCHAR(20)    NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    Specialization  NVARCHAR(100)   NULL,
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Trainers_IsDeleted' AND object_id = OBJECT_ID('Trainers'))
CREATE INDEX IX_Trainers_IsDeleted ON Trainers(IsDeleted);
GO

-- Facilities (phòng/thiết bị)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Facilities' AND xtype='U')
CREATE TABLE Facilities (
    FacilityId      INT             IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(100)   NOT NULL,
    Description     NVARCHAR(500)   NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Facilities_IsDeleted' AND object_id = OBJECT_ID('Facilities'))
CREATE INDEX IX_Facilities_IsDeleted ON Facilities(IsDeleted);
GO

-- Memberships (gói tập) - có Versioning
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Memberships' AND xtype='U')
CREATE TABLE Memberships (
    MembershipId    INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL REFERENCES Members(MemberId),
    MembershipType  NVARCHAR(50)    NOT NULL,   -- Monthly, Quarterly, Annual, VIP, Trial
    Price           DECIMAL(18,2)   NOT NULL,
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    Version         INT             NOT NULL DEFAULT 1,  -- Versioning cho bản ghi nhạy cảm
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Memberships_MemberId' AND object_id = OBJECT_ID('Memberships'))
CREATE INDEX IX_Memberships_MemberId ON Memberships(MemberId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Memberships_IsDeleted' AND object_id = OBJECT_ID('Memberships'))
CREATE INDEX IX_Memberships_IsDeleted ON Memberships(IsDeleted);
GO

-- Schedules (lịch tập)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Schedules' AND xtype='U')
CREATE TABLE Schedules (
    ScheduleId      INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL REFERENCES Members(MemberId),
    TrainerId       INT             NOT NULL REFERENCES Trainers(TrainerId),
    FacilityId      INT             NOT NULL REFERENCES Facilities(FacilityId),
    StartTime       DATETIME2       NOT NULL,
    EndTime         DATETIME2       NOT NULL,
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Schedules_MemberId' AND object_id = OBJECT_ID('Schedules'))
CREATE INDEX IX_Schedules_MemberId ON Schedules(MemberId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Schedules_TrainerId' AND object_id = OBJECT_ID('Schedules'))
CREATE INDEX IX_Schedules_TrainerId ON Schedules(TrainerId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Schedules_FacilityId' AND object_id = OBJECT_ID('Schedules'))
CREATE INDEX IX_Schedules_FacilityId ON Schedules(FacilityId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Schedules_IsDeleted' AND object_id = OBJECT_ID('Schedules'))
CREATE INDEX IX_Schedules_IsDeleted ON Schedules(IsDeleted);
GO

-- Sessions (buổi tập thực tế)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Sessions' AND xtype='U')
CREATE TABLE Sessions (
    SessionId       INT             IDENTITY(1,1) PRIMARY KEY,
    ScheduleId      INT             NOT NULL REFERENCES Schedules(ScheduleId),
    SessionDate     DATE            NOT NULL,
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Scheduled' CHECK (Status IN ('Scheduled','Completed','Cancelled')),
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Sessions_ScheduleId' AND object_id = OBJECT_ID('Sessions'))
CREATE INDEX IX_Sessions_ScheduleId ON Sessions(ScheduleId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Sessions_IsDeleted' AND object_id = OBJECT_ID('Sessions'))
CREATE INDEX IX_Sessions_IsDeleted ON Sessions(IsDeleted);
GO

-- Checkins
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Checkins' AND xtype='U')
CREATE TABLE Checkins (
    CheckinId       INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL REFERENCES Members(MemberId),
    SessionId       INT             NOT NULL REFERENCES Sessions(SessionId),
    CheckinTime     DATETIME2       NOT NULL DEFAULT GETDATE(),
    CheckinMethod   NVARCHAR(50)    NOT NULL DEFAULT 'Manual' CHECK (CheckinMethod IN ('Manual','QRCode','Card')),
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkins_MemberId' AND object_id = OBJECT_ID('Checkins'))
CREATE INDEX IX_Checkins_MemberId ON Checkins(MemberId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkins_SessionId' AND object_id = OBJECT_ID('Checkins'))
CREATE INDEX IX_Checkins_SessionId ON Checkins(SessionId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkins_IsDeleted' AND object_id = OBJECT_ID('Checkins'))
CREATE INDEX IX_Checkins_IsDeleted ON Checkins(IsDeleted);
GO

-- Invoices (hóa đơn)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Invoices' AND xtype='U')
CREATE TABLE Invoices (
    InvoiceId       INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL REFERENCES Members(MemberId),
    TotalAmount     DECIMAL(18,2)   NOT NULL,
    InvoiceDate     DATE            NOT NULL DEFAULT GETDATE(),
    DueDate         DATE            NOT NULL,
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending','Paid','Overdue','Cancelled')),
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Invoices_MemberId' AND object_id = OBJECT_ID('Invoices'))
CREATE INDEX IX_Invoices_MemberId ON Invoices(MemberId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Invoices_IsDeleted' AND object_id = OBJECT_ID('Invoices'))
CREATE INDEX IX_Invoices_IsDeleted ON Invoices(IsDeleted);
GO

-- Payments
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Payments' AND xtype='U')
CREATE TABLE Payments (
    PaymentId       INT             IDENTITY(1,1) PRIMARY KEY,
    InvoiceId       INT             NOT NULL REFERENCES Invoices(InvoiceId),
    Amount          DECIMAL(18,2)   NOT NULL,
    PaymentDate     DATETIME2       NOT NULL DEFAULT GETDATE(),
    PaymentMethod   NVARCHAR(30)    NOT NULL CHECK (PaymentMethod IN ('Cash','BankTransfer','Card','MoMo','ZaloPay')),
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending','Completed','Failed','Refunded')),
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Payments_InvoiceId' AND object_id = OBJECT_ID('Payments'))
CREATE INDEX IX_Payments_InvoiceId ON Payments(InvoiceId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Payments_IsDeleted' AND object_id = OBJECT_ID('Payments'))
CREATE INDEX IX_Payments_IsDeleted ON Payments(IsDeleted);
GO

-- ============================================================
-- 3. USERS TABLE (with RBAC + Security)
-- ============================================================

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
CREATE TABLE Users (
    UserId          INT             IDENTITY(1,1) PRIMARY KEY,
    Username        NVARCHAR(50)    NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(256)   NOT NULL,        -- BCrypt hash
    PasswordSalt    NVARCHAR(64)    NOT NULL,        -- Per-user salt (Base64)
    RoleId          INT             NOT NULL REFERENCES Roles(RoleId),  -- FK to Roles
    MemberId        INT             NULL REFERENCES Members(MemberId),  -- nếu role=Member
    TrainerId       INT             NULL REFERENCES Trainers(TrainerId), -- nếu role=Trainer
    IsActive        BIT             NOT NULL DEFAULT 1,
    FailedLoginCount INT            NOT NULL DEFAULT 0,   -- Đếm lần đăng nhập sai
    LockedUntil     DATETIME2       NULL,                -- Khóa đến khi nào
    LastLoginAt     DATETIME2       NULL,                -- Lần đăng nhập thành công cuối
    RefreshToken    NVARCHAR(512)   NULL,                -- Current refresh token hash
    RefreshTokenExpiry DATETIME2    NULL,                -- Refresh token expiry
    -- Audit fields
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CreatedBy       INT             NULL,
    UpdatedAt       DATETIME2       NULL,
    UpdatedBy       INT             NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    DeletedBy       INT             NULL,
    -- Concurrency
    RowVersion      ROWVERSION      NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_RoleId' AND object_id = OBJECT_ID('Users'))
CREATE INDEX IX_Users_RoleId ON Users(RoleId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_MemberId' AND object_id = OBJECT_ID('Users'))
CREATE INDEX IX_Users_MemberId ON Users(MemberId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_TrainerId' AND object_id = OBJECT_ID('Users'))
CREATE INDEX IX_Users_TrainerId ON Users(TrainerId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_IsDeleted' AND object_id = OBJECT_ID('Users'))
CREATE INDEX IX_Users_IsDeleted ON Users(IsDeleted);
GO

-- ============================================================
-- 4. AUDIT LOG TABLE
-- ============================================================

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AuditLogs' AND xtype='U')
CREATE TABLE AuditLogs (
    AuditLogId      BIGINT          IDENTITY(1,1) PRIMARY KEY,
    TableName       NVARCHAR(100)   NOT NULL,
    RecordId        INT             NOT NULL,
    Action          NVARCHAR(20)    NOT NULL,        -- INSERT, UPDATE, DELETE, SOFT_DELETE, RESTORE
    OldValues       NVARCHAR(MAX)   NULL,            -- JSON
    NewValues       NVARCHAR(MAX)   NULL,            -- JSON
    ChangedBy       INT             NULL REFERENCES Users(UserId),
    ChangedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    IpAddress       NVARCHAR(45)    NULL,
    UserAgent       NVARCHAR(500)   NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLogs_TableRecord' AND object_id = OBJECT_ID('AuditLogs'))
CREATE INDEX IX_AuditLogs_TableRecord ON AuditLogs(TableName, RecordId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLogs_ChangedAt' AND object_id = OBJECT_ID('AuditLogs'))
CREATE INDEX IX_AuditLogs_ChangedAt ON AuditLogs(ChangedAt);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLogs_ChangedBy' AND object_id = OBJECT_ID('AuditLogs'))
CREATE INDEX IX_AuditLogs_ChangedBy ON AuditLogs(ChangedBy);
GO

-- ============================================================
-- 5. REFRESH TOKENS TABLE (JWT Rotation)
-- ============================================================

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='RefreshTokens' AND xtype='U')
CREATE TABLE RefreshTokens (
    RefreshTokenId  BIGINT          IDENTITY(1,1) PRIMARY KEY,
    UserId          INT             NOT NULL REFERENCES Users(UserId),
    TokenHash       NVARCHAR(512)   NOT NULL,        -- SHA256 hash của refresh token
    JwtId           NVARCHAR(100)   NOT NULL,        -- JWT ID (jti claim)
    ExpiresAt       DATETIME2       NOT NULL,
    RevokedAt       DATETIME2       NULL,
    ReplacedByTokenHash NVARCHAR(512) NULL,          -- Token mới thay thế (rotation)
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE()
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RefreshTokens_UserId' AND object_id = OBJECT_ID('RefreshTokens'))
CREATE INDEX IX_RefreshTokens_UserId ON RefreshTokens(UserId);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RefreshTokens_TokenHash' AND object_id = OBJECT_ID('RefreshTokens'))
CREATE INDEX IX_RefreshTokens_TokenHash ON RefreshTokens(TokenHash);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RefreshTokens_JwtId' AND object_id = OBJECT_ID('RefreshTokens'))
CREATE INDEX IX_RefreshTokens_JwtId ON RefreshTokens(JwtId);
GO

-- ============================================================
-- 6. AUDIT TRIGGERS (Auto-populate AuditLogs)
-- ============================================================

-- Helper function to generate JSON from inserted/deleted
CREATE OR ALTER FUNCTION dbo.fn_RowToJson(@TableName NVARCHAR(100), @RecordId INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Json NVARCHAR(MAX);
    -- This is a placeholder; actual implementation would use dynamic SQL or FOR JSON PATH
    SET @Json = (SELECT * FROM sys.tables WHERE name = @TableName FOR JSON PATH);
    RETURN @Json;
END;
GO

-- Generic audit trigger template (applied per table below)
-- Members Audit Trigger
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_Members_Audit')
EXEC('
CREATE TRIGGER tr_Members_Audit ON Members
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Action NVARCHAR(20);
    DECLARE @UserId INT = CONVERT(INT, CONTEXT_INFO());
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = ''UPDATE'';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = ''INSERT'';
    ELSE
        SET @Action = ''DELETE'';
    
    INSERT INTO AuditLogs (TableName, RecordId, Action, OldValues, NewValues, ChangedBy)
    SELECT 
        ''Members'',
        COALESCE(i.MemberId, d.MemberId),
        @Action,
        (SELECT * FROM deleted d2 WHERE d2.MemberId = COALESCE(i.MemberId, d.MemberId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT * FROM inserted i2 WHERE i2.MemberId = COALESCE(i.MemberId, d.MemberId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        @UserId
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.MemberId = d.MemberId;
END;
');
GO

-- Trainers Audit Trigger
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_Trainers_Audit')
EXEC('
CREATE TRIGGER tr_Trainers_Audit ON Trainers
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Action NVARCHAR(20);
    DECLARE @UserId INT = CONVERT(INT, CONTEXT_INFO());
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = ''UPDATE'';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = ''INSERT'';
    ELSE
        SET @Action = ''DELETE'';
    
    INSERT INTO AuditLogs (TableName, RecordId, Action, OldValues, NewValues, ChangedBy)
    SELECT 
        ''Trainers'',
        COALESCE(i.TrainerId, d.TrainerId),
        @Action,
        (SELECT * FROM deleted d2 WHERE d2.TrainerId = COALESCE(i.TrainerId, d.TrainerId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT * FROM inserted i2 WHERE i2.TrainerId = COALESCE(i.TrainerId, d.TrainerId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        @UserId
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.TrainerId = d.TrainerId;
END;
');
GO

-- Memberships Audit Trigger (important for versioning)
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_Memberships_Audit')
EXEC('
CREATE TRIGGER tr_Memberships_Audit ON Memberships
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Action NVARCHAR(20);
    DECLARE @UserId INT = CONVERT(INT, CONTEXT_INFO());
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = ''UPDATE'';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = ''INSERT'';
    ELSE
        SET @Action = ''DELETE'';
    
    INSERT INTO AuditLogs (TableName, RecordId, Action, OldValues, NewValues, ChangedBy)
    SELECT 
        ''Memberships'',
        COALESCE(i.MembershipId, d.MembershipId),
        @Action,
        (SELECT * FROM deleted d2 WHERE d2.MembershipId = COALESCE(i.MembershipId, d.MembershipId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT * FROM inserted i2 WHERE i2.MembershipId = COALESCE(i.MembershipId, d.MembershipId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        @UserId
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.MembershipId = d.MembershipId;
END;
');
GO

-- Invoices Audit Trigger
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_Invoices_Audit')
EXEC('
CREATE TRIGGER tr_Invoices_Audit ON Invoices
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Action NVARCHAR(20);
    DECLARE @UserId INT = CONVERT(INT, CONTEXT_INFO());
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = ''UPDATE'';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = ''INSERT'';
    ELSE
        SET @Action = ''DELETE'';
    
    INSERT INTO AuditLogs (TableName, RecordId, Action, OldValues, NewValues, ChangedBy)
    SELECT 
        ''Invoices'',
        COALESCE(i.InvoiceId, d.InvoiceId),
        @Action,
        (SELECT * FROM deleted d2 WHERE d2.InvoiceId = COALESCE(i.InvoiceId, d.InvoiceId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT * FROM inserted i2 WHERE i2.InvoiceId = COALESCE(i.InvoiceId, d.InvoiceId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        @UserId
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.InvoiceId = d.InvoiceId;
END;
');
GO

-- Payments Audit Trigger
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_Payments_Audit')
EXEC('
CREATE TRIGGER tr_Payments_Audit ON Payments
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Action NVARCHAR(20);
    DECLARE @UserId INT = CONVERT(INT, CONTEXT_INFO());
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = ''UPDATE'';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = ''INSERT'';
    ELSE
        SET @Action = ''DELETE'';
    
    INSERT INTO AuditLogs (TableName, RecordId, Action, OldValues, NewValues, ChangedBy)
    SELECT 
        ''Payments'',
        COALESCE(i.PaymentId, d.PaymentId),
        @Action,
        (SELECT * FROM deleted d2 WHERE d2.PaymentId = COALESCE(i.PaymentId, d.PaymentId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT * FROM inserted i2 WHERE i2.PaymentId = COALESCE(i.PaymentId, d.PaymentId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        @UserId
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.PaymentId = d.PaymentId;
END;
');
GO

-- Users Audit Trigger (security critical)
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_Users_Audit')
EXEC('
CREATE TRIGGER tr_Users_Audit ON Users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Action NVARCHAR(20);
    DECLARE @UserId INT = CONVERT(INT, CONTEXT_INFO());
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = ''UPDATE'';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = ''INSERT'';
    ELSE
        SET @Action = ''DELETE'';
    
    INSERT INTO AuditLogs (TableName, RecordId, Action, OldValues, NewValues, ChangedBy)
    SELECT 
        ''Users'',
        COALESCE(i.UserId, d.UserId),
        @Action,
        (SELECT UserId, Username, RoleId, IsActive, FailedLoginCount, LockedUntil, LastLoginAt FROM deleted d2 WHERE d2.UserId = COALESCE(i.UserId, d.UserId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT UserId, Username, RoleId, IsActive, FailedLoginCount, LockedUntil, LastLoginAt FROM inserted i2 WHERE i2.UserId = COALESCE(i.UserId, d.UserId) FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        @UserId
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.UserId = d.UserId;
END;
');
GO

-- ============================================================
-- 7. SOFT DELETE HELPER PROCEDURES
-- ============================================================

-- Generic soft delete
CREATE OR ALTER PROCEDURE dbo.sp_SoftDelete
    @TableName NVARCHAR(100),
    @RecordId INT,
    @DeletedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    DECLARE @Sql NVARCHAR(MAX);
    SET @Sql = N'UPDATE ' + QUOTENAME(@TableName) + N' SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy WHERE ' + 
               CASE @TableName 
                   WHEN 'Members' THEN 'MemberId'
                   WHEN 'Trainers' THEN 'TrainerId'
                   WHEN 'Facilities' THEN 'FacilityId'
                   WHEN 'Memberships' THEN 'MembershipId'
                   WHEN 'Schedules' THEN 'ScheduleId'
                   WHEN 'Sessions' THEN 'SessionId'
                   WHEN 'Checkins' THEN 'CheckinId'
                   WHEN 'Invoices' THEN 'InvoiceId'
                   WHEN 'Payments' THEN 'PaymentId'
                   WHEN 'Users' THEN 'UserId'
               END + N' = @RecordId AND IsDeleted = 0';
    EXEC sp_executesql @Sql, N'@RecordId INT, @DeletedBy INT', @RecordId, @DeletedBy;
END;
GO

-- Generic restore
CREATE OR ALTER PROCEDURE dbo.sp_Restore
    @TableName NVARCHAR(100),
    @RecordId INT,
    @RestoredBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    DECLARE @Sql NVARCHAR(MAX);
    SET @Sql = N'UPDATE ' + QUOTENAME(@TableName) + N' SET IsDeleted = 0, DeletedAt = NULL, DeletedBy = NULL, UpdatedAt = GETDATE(), UpdatedBy = @RestoredBy WHERE ' + 
               CASE @TableName 
                   WHEN 'Members' THEN 'MemberId'
                   WHEN 'Trainers' THEN 'TrainerId'
                   WHEN 'Facilities' THEN 'FacilityId'
                   WHEN 'Memberships' THEN 'MembershipId'
                   WHEN 'Schedules' THEN 'ScheduleId'
                   WHEN 'Sessions' THEN 'SessionId'
                   WHEN 'Checkins' THEN 'CheckinId'
                   WHEN 'Invoices' THEN 'InvoiceId'
                   WHEN 'Payments' THEN 'PaymentId'
                   WHEN 'Users' THEN 'UserId'
               END + N' = @RecordId AND IsDeleted = 1';
    EXEC sp_executesql @Sql, N'@RecordId INT, @RestoredBy INT', @RecordId, @RestoredBy;
END;
GO

PRINT 'Schema created successfully with RBAC, Audit, Soft Delete, Versioning, Concurrency, and Audit Triggers.';
GO
