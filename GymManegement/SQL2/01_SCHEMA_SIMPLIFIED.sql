-- ============================================================
-- FILE: 01_SCHEMA_SIMPLIFIED.sql
-- MÔ TẢ: Schema đơn giản hóa theo API_SPECIFICATION_SIMPLIFIED.md
-- BỎ: RBAC tables, OTP tables, RefreshTokens, AuditLogs, Triggers
-- GIỮ: Core business tables, Soft delete, Basic audit (CreatedAt/UpdatedAt)
-- ============================================================

USE GymDb;
GO

-- ============================================================
-- 1. USERS TABLE (SIMPLIFIED)
-- ============================================================
CREATE TABLE Users (
    UserId          INT             IDENTITY(1,1) PRIMARY KEY,
    Username        NVARCHAR(50)    NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(256)   NOT NULL,        -- BCrypt hash (chứa salt)
    FullName        NVARCHAR(100)   NOT NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    Role            NVARCHAR(20)    NOT NULL CHECK (Role IN ('Admin','Trainer','Member')),
    IsActive        BIT             NOT NULL DEFAULT 1,
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL
);
GO

CREATE INDEX IX_Users_Email ON Users(Email) WHERE IsDeleted = 0;
CREATE INDEX IX_Users_Role ON Users(Role);
CREATE INDEX IX_Users_IsDeleted ON Users(IsDeleted);
GO

-- ============================================================
-- 2. MEMBERS TABLE
-- ============================================================
CREATE TABLE Members (
    MemberId        INT             IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Phone           NVARCHAR(20)    NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    DateOfBirth     DATE            NULL,
    JoinDate        DATE            NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active','Inactive','Expired')),
    QRCodeValue     NVARCHAR(100)   NOT NULL UNIQUE,
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL
);
GO

CREATE INDEX IX_Members_Email ON Members(Email) WHERE IsDeleted = 0;
CREATE INDEX IX_Members_QRCodeValue ON Members(QRCodeValue);
CREATE INDEX IX_Members_Status ON Members(Status);
CREATE INDEX IX_Members_IsDeleted ON Members(IsDeleted);
GO

-- ============================================================
-- 3. TRAINERS TABLE
-- ============================================================
CREATE TABLE Trainers (
    TrainerId       INT             IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Phone           NVARCHAR(20)    NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    Specialization  NVARCHAR(200)   NULL,
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL
);
GO

CREATE INDEX IX_Trainers_Email ON Trainers(Email) WHERE IsDeleted = 0;
CREATE INDEX IX_Trainers_IsDeleted ON Trainers(IsDeleted);
GO

-- ============================================================
-- 4. FACILITIES TABLE (Phòng/Thiết bị)
-- ============================================================
CREATE TABLE Facilities (
    FacilityId      INT             IDENTITY(1,1) PRIMARY KEY,
    FacilityName    NVARCHAR(100)   NOT NULL,
    FacilityType    NVARCHAR(20)    NOT NULL CHECK (FacilityType IN ('Room','Equipment')),
    Capacity        INT             NULL,           -- Chỉ áp dụng cho Room
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Available' CHECK (Status IN ('Available','Maintenance','Unavailable')),
    Description     NVARCHAR(500)   NULL,
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL
);
GO

CREATE INDEX IX_Facilities_FacilityType ON Facilities(FacilityType);
CREATE INDEX IX_Facilities_Status ON Facilities(Status);
CREATE INDEX IX_Facilities_IsDeleted ON Facilities(IsDeleted);
GO

-- ============================================================
-- 5. MEMBERSHIPS TABLE (Gói tập)
-- ============================================================
CREATE TABLE Memberships (
    MembershipId    INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    MembershipType  NVARCHAR(20)    NOT NULL CHECK (MembershipType IN ('Monthly','Quarterly','Annual')),
    Price           DECIMAL(18,2)   NOT NULL,
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NOT NULL,
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active','Expired','Cancelled')),
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    
    CONSTRAINT CK_Memberships_Dates CHECK (EndDate > StartDate)
);
GO

CREATE INDEX IX_Memberships_MemberId ON Memberships(MemberId);
CREATE INDEX IX_Memberships_EndDate ON Memberships(EndDate);
CREATE INDEX IX_Memberships_Status ON Memberships(Status);
CREATE INDEX IX_Memberships_IsDeleted ON Memberships(IsDeleted);
GO

-- ============================================================
-- 6. SCHEDULES TABLE (Lịch tập)
-- ============================================================
CREATE TABLE Schedules (
    ScheduleId      INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    TrainerId       INT             NOT NULL FOREIGN KEY REFERENCES Trainers(TrainerId),
    FacilityId      INT             NULL FOREIGN KEY REFERENCES Facilities(FacilityId),
    ScheduledDate   DATE            NOT NULL,
    StartTime       TIME            NOT NULL,
    EndTime         TIME            NOT NULL,
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Scheduled' CHECK (Status IN ('Scheduled','Completed','Cancelled')),
    Notes           NVARCHAR(500)   NULL,
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL,
    
    CONSTRAINT CK_Schedules_Times CHECK (EndTime > StartTime)
);
GO

CREATE INDEX IX_Schedules_MemberId ON Schedules(MemberId);
CREATE INDEX IX_Schedules_TrainerId ON Schedules(TrainerId);
CREATE INDEX IX_Schedules_FacilityId ON Schedules(FacilityId);
CREATE INDEX IX_Schedules_ScheduledDate ON Schedules(ScheduledDate);
CREATE INDEX IX_Schedules_Status ON Schedules(Status);
CREATE INDEX IX_Schedules_IsDeleted ON Schedules(IsDeleted);
GO

-- ============================================================
-- 7. SESSIONS TABLE (Buổi tập thực tế)
-- ============================================================
CREATE TABLE Sessions (
    SessionId       INT             IDENTITY(1,1) PRIMARY KEY,
    ScheduleId      INT             NOT NULL FOREIGN KEY REFERENCES Schedules(ScheduleId),
    ActualStartTime TIME            NULL,
    ActualEndTime   TIME            NULL,
    Notes           NVARCHAR(500)   NULL,
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL
);
GO

CREATE INDEX IX_Sessions_ScheduleId ON Sessions(ScheduleId);
CREATE INDEX IX_Sessions_IsDeleted ON Sessions(IsDeleted);
GO

-- ============================================================
-- 8. CHECKINS TABLE
-- ============================================================
CREATE TABLE Checkins (
    CheckinId       INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    SessionId       INT             NULL FOREIGN KEY REFERENCES Sessions(SessionId),
    CheckinTime     DATETIME2       NOT NULL DEFAULT GETDATE(),
    CheckinMethod   NVARCHAR(20)    NOT NULL DEFAULT 'Manual' CHECK (CheckinMethod IN ('Manual','QR')),
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL
);
GO

CREATE INDEX IX_Checkins_MemberId ON Checkins(MemberId);
CREATE INDEX IX_Checkins_SessionId ON Checkins(SessionId);
CREATE INDEX IX_Checkins_CheckinTime ON Checkins(CheckinTime);
CREATE INDEX IX_Checkins_IsDeleted ON Checkins(IsDeleted);
GO

-- ============================================================
-- 9. INVOICES TABLE (Hóa đơn)
-- ============================================================
CREATE TABLE Invoices (
    InvoiceId       INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    MembershipId    INT             NULL FOREIGN KEY REFERENCES Memberships(MembershipId),
    Amount          DECIMAL(18,2)   NOT NULL,
    IssueDate       DATE            NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    DueDate         DATE            NOT NULL,
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending','Paid','Overdue','Cancelled')),
    Description     NVARCHAR(500)   NULL,
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL
);
GO

CREATE INDEX IX_Invoices_MemberId ON Invoices(MemberId);
CREATE INDEX IX_Invoices_MembershipId ON Invoices(MembershipId);
CREATE INDEX IX_Invoices_Status ON Invoices(Status);
CREATE INDEX IX_Invoices_DueDate ON Invoices(DueDate);
CREATE INDEX IX_Invoices_IsDeleted ON Invoices(IsDeleted);
GO

-- ============================================================
-- 10. PAYMENTS TABLE (Thanh toán)
-- ============================================================
CREATE TABLE Payments (
    PaymentId       INT             IDENTITY(1,1) PRIMARY KEY,
    InvoiceId       INT             NOT NULL FOREIGN KEY REFERENCES Invoices(InvoiceId),
    Amount          DECIMAL(18,2)   NOT NULL,
    PaymentDate     DATE            NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    PaymentMethod   NVARCHAR(20)    NOT NULL CHECK (PaymentMethod IN ('Cash','Card','Transfer')),
    Notes           NVARCHAR(500)   NULL,
    -- Basic audit
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    UpdatedAt       DATETIME2       NULL,
    -- Soft delete
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    DeletedAt       DATETIME2       NULL
);
GO

CREATE INDEX IX_Payments_InvoiceId ON Payments(InvoiceId);
CREATE INDEX IX_Payments_PaymentDate ON Payments(PaymentDate);
CREATE INDEX IX_Payments_IsDeleted ON Payments(IsDeleted);
GO

-- ============================================================
-- SUMMARY
-- ============================================================
PRINT '✅ Schema created successfully!';
PRINT '';
PRINT 'Tables created (10):';
PRINT '  1. Users (simplified - Role as string)';
PRINT '  2. Members';
PRINT '  3. Trainers';
PRINT '  4. Facilities';
PRINT '  5. Memberships';
PRINT '  6. Schedules';
PRINT '  7. Sessions';
PRINT '  8. Checkins';
PRINT '  9. Invoices';
PRINT ' 10. Payments';
PRINT '';
PRINT '✅ Features:';
PRINT '  - Soft delete (IsDeleted, DeletedAt)';
PRINT '  - Basic audit (CreatedAt, UpdatedAt)';
PRINT '  - Indexes on frequently queried columns';
PRINT '  - Check constraints for data integrity';
PRINT '';
PRINT '❌ Removed (compared to old SQL):';
PRINT '  - Roles, Permissions, RolePermissions tables';
PRINT '  - EmailVerificationOTP table';
PRINT '  - PasswordResetToken table';
PRINT '  - RefreshTokens table';
PRINT '  - AuditLogs table & triggers';
PRINT '  - RowVersion (concurrency control)';
PRINT '';
PRINT 'Next: Run 02_SEED_DATA.sql';
GO
