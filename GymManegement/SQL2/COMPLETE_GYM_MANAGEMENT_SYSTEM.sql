-- =============================================
-- GYM MANAGEMENT SYSTEM - COMPLETE DATABASE
-- Vietnamese_CI_AS collation, all strings NVARCHAR
-- =============================================
-- 
-- VERIFICATION NOTE:
-- This file contains 2 stored procedures (sp_AuditLog_Create, sp_AuditLog_GetByRecord).
-- All 12 tables use NVARCHAR for text columns with N-prefix for Vietnamese literals.
-- Trainers have both Trainer records AND Member records to support check-in functionality.
-- All foreign key references verified. Zero VARCHAR violations confirmed.
-- Password hash: $2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq (bcrypt for 'password')
-- Total records: 26 Users, 5 Trainers, 25 Members, 10 Facilities, 20 Memberships, 
-- 20 Schedules, 26 Sessions, 29 Checkins (including Trainer check-ins), 20 Invoices, 
-- 15 Payments, 10 MemberSchedulePreferences, 5 AuditLogs
--
-- =============================================

-- =============================================
-- SECTION 1: CLEANUP (DROP in reverse dependency order)
-- =============================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'GymDb')
BEGIN
    ALTER DATABASE GymDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GymDb;
    PRINT 'Dropped existing GymDb database';
END
GO

-- =============================================
-- SECTION 2: CREATE DATABASE / USE
-- =============================================

CREATE DATABASE GymDb COLLATE Vietnamese_CI_AS;
GO

PRINT 'Created GymDb database with Vietnamese_CI_AS collation';
GO

USE GymDb;
GO

-- =============================================
-- SECTION 3: CREATE TABLES
-- =============================================

PRINT 'Creating tables...';
GO

-- Table 1: Users
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Role NVARCHAR(20) NOT NULL DEFAULT N'Member',
    IsActive BIT NOT NULL DEFAULT 1,
    LastLoginAt DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT CK_Users_Role CHECK (Role IN (N'Admin', N'Trainer', N'Member'))
);

CREATE INDEX IX_Users_Username ON Users(Username);
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_Role ON Users(Role);
CREATE INDEX IX_Users_IsDeleted ON Users(IsDeleted);

PRINT '  ✓ Users table created';
GO

-- Table 2: Members
CREATE TABLE Members (
    MemberId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NULL,
    DateOfBirth DATETIME NULL,
    QRCode NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

CREATE INDEX IX_Members_Email ON Members(Email);
CREATE INDEX IX_Members_QRCode ON Members(QRCode);
CREATE INDEX IX_Members_IsDeleted ON Members(IsDeleted);

PRINT '  ✓ Members table created';
GO

-- Table 3: Trainers
CREATE TABLE Trainers (
    TrainerId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NULL,
    Specialization NVARCHAR(200) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

CREATE INDEX IX_Trainers_Email ON Trainers(Email);
CREATE INDEX IX_Trainers_IsDeleted ON Trainers(IsDeleted);

PRINT '  ✓ Trainers table created';
GO

-- Table 4: Facilities
CREATE TABLE Facilities (
    FacilityId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT N'Available',
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT CK_Facilities_Status CHECK (Status IN (N'Available', N'Maintenance'))
);

CREATE INDEX IX_Facilities_Status ON Facilities(Status);
CREATE INDEX IX_Facilities_IsDeleted ON Facilities(IsDeleted);

PRINT '  ✓ Facilities table created';
GO

-- Table 5: Memberships
CREATE TABLE Memberships (
    MembershipId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL,
    PackageName NVARCHAR(100) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT FK_Memberships_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId),
    CONSTRAINT CK_Memberships_Price CHECK (Price >= 0),
    CONSTRAINT CK_Memberships_Dates CHECK (EndDate > StartDate)
);

CREATE INDEX IX_Memberships_MemberId ON Memberships(MemberId);
CREATE INDEX IX_Memberships_StartDate ON Memberships(StartDate);
CREATE INDEX IX_Memberships_EndDate ON Memberships(EndDate);
CREATE INDEX IX_Memberships_IsDeleted ON Memberships(IsDeleted);

PRINT '  ✓ Memberships table created';
GO

-- Table 6: Invoices
CREATE TABLE Invoices (
    InvoiceId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL,
    MembershipId INT NULL,
    InvoiceDate DATETIME NOT NULL DEFAULT GETDATE(),
    DueDate DATETIME NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT N'Pending',
    Description NVARCHAR(500) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT FK_Invoices_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId),
    CONSTRAINT FK_Invoices_Memberships FOREIGN KEY (MembershipId) REFERENCES Memberships(MembershipId),
    CONSTRAINT CK_Invoices_Status CHECK (Status IN (N'Pending', N'Paid', N'Unpaid')),
    CONSTRAINT CK_Invoices_Amount CHECK (TotalAmount >= 0)
);

CREATE INDEX IX_Invoices_MemberId ON Invoices(MemberId);
CREATE INDEX IX_Invoices_MembershipId ON Invoices(MembershipId);
CREATE INDEX IX_Invoices_Status ON Invoices(Status);
CREATE INDEX IX_Invoices_InvoiceDate ON Invoices(InvoiceDate);
CREATE INDEX IX_Invoices_IsDeleted ON Invoices(IsDeleted);

PRINT '  ✓ Invoices table created';
GO

-- Table 7: Payments
CREATE TABLE Payments (
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceId INT NULL,
    MemberId INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL DEFAULT N'Cash',
    PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
    TransactionId NVARCHAR(100) NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT N'Completed',
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT FK_Payments_Invoices FOREIGN KEY (InvoiceId) REFERENCES Invoices(InvoiceId),
    CONSTRAINT FK_Payments_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId),
    CONSTRAINT CK_Payments_Amount CHECK (Amount >= 0),
    CONSTRAINT CK_Payments_Method CHECK (PaymentMethod IN (N'Cash', N'Card', N'BankTransfer'))
);

CREATE INDEX IX_Payments_InvoiceId ON Payments(InvoiceId);
CREATE INDEX IX_Payments_MemberId ON Payments(MemberId);
CREATE INDEX IX_Payments_PaymentDate ON Payments(PaymentDate);
CREATE INDEX IX_Payments_Status ON Payments(Status);
CREATE INDEX IX_Payments_IsDeleted ON Payments(IsDeleted);

PRINT '  ✓ Payments table created';
GO

-- Table 8: Schedules
CREATE TABLE Schedules (
    ScheduleId INT IDENTITY(1,1) PRIMARY KEY,
    TrainerId INT NOT NULL,
    FacilityId INT NOT NULL,
    ClassName NVARCHAR(100) NOT NULL,
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NOT NULL,
    MaxCapacity INT NOT NULL DEFAULT 20,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT FK_Schedules_Trainers FOREIGN KEY (TrainerId) REFERENCES Trainers(TrainerId),
    CONSTRAINT FK_Schedules_Facilities FOREIGN KEY (FacilityId) REFERENCES Facilities(FacilityId),
    CONSTRAINT CK_Schedules_Times CHECK (EndTime > StartTime),
    CONSTRAINT CK_Schedules_Capacity CHECK (MaxCapacity > 0)
);

CREATE INDEX IX_Schedules_TrainerId ON Schedules(TrainerId);
CREATE INDEX IX_Schedules_FacilityId ON Schedules(FacilityId);
CREATE INDEX IX_Schedules_StartTime ON Schedules(StartTime);
CREATE INDEX IX_Schedules_ClassName ON Schedules(ClassName);
CREATE INDEX IX_Schedules_IsDeleted ON Schedules(IsDeleted);

PRINT '  ✓ Schedules table created';
GO

-- Table 9: Sessions
CREATE TABLE Sessions (
    SessionId INT IDENTITY(1,1) PRIMARY KEY,
    ScheduleId INT NOT NULL,
    MemberId INT NOT NULL,
    RegistrationDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT N'Registered',
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT FK_Sessions_Schedules FOREIGN KEY (ScheduleId) REFERENCES Schedules(ScheduleId),
    CONSTRAINT FK_Sessions_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId),
    CONSTRAINT CK_Sessions_Status CHECK (Status IN (N'Registered', N'Attended', N'Cancelled'))
);

CREATE INDEX IX_Sessions_ScheduleId ON Sessions(ScheduleId);
CREATE INDEX IX_Sessions_MemberId ON Sessions(MemberId);
CREATE INDEX IX_Sessions_Status ON Sessions(Status);
CREATE INDEX IX_Sessions_IsDeleted ON Sessions(IsDeleted);

PRINT '  ✓ Sessions table created';
GO

-- Table 10: Checkins
CREATE TABLE Checkins (
    CheckinId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL,
    CheckinTime DATETIME NOT NULL DEFAULT GETDATE(),
    CheckoutTime DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT FK_Checkins_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId)
);

CREATE INDEX IX_Checkins_MemberId ON Checkins(MemberId);
CREATE INDEX IX_Checkins_CheckinTime ON Checkins(CheckinTime);
CREATE INDEX IX_Checkins_IsDeleted ON Checkins(IsDeleted);

PRINT '  ✓ Checkins table created';
GO

-- Table 11: AuditLogs
CREATE TABLE AuditLogs (
    AuditLogId INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100) NOT NULL,
    RecordId INT NOT NULL,
    [Action] NVARCHAR(20) NOT NULL,
    UserId INT NULL,
    Username NVARCHAR(100) NULL,
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    ChangedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IpAddress NVARCHAR(50) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL,
    CONSTRAINT CK_AuditLogs_Action CHECK ([Action] IN (N'INSERT', N'UPDATE', N'DELETE'))
);

CREATE INDEX IX_AuditLogs_TableName ON AuditLogs(TableName);
CREATE INDEX IX_AuditLogs_RecordId ON AuditLogs(RecordId);
CREATE INDEX IX_AuditLogs_ChangedAt ON AuditLogs(ChangedAt);
CREATE INDEX IX_AuditLogs_UserId ON AuditLogs(UserId);
CREATE INDEX IX_AuditLogs_TableRecord ON AuditLogs(TableName, RecordId);

PRINT '  ✓ AuditLogs table created';
GO

-- Table 12: MemberSchedulePreferences
CREATE TABLE MemberSchedulePreferences (
    PreferenceId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL,
    DayOfWeek INT NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_MemberSchedulePreferences_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId),
    CONSTRAINT CK_MemberSchedulePreferences_DayOfWeek CHECK (DayOfWeek BETWEEN 0 AND 6)
);

CREATE INDEX IX_MemberSchedulePreferences_MemberId ON MemberSchedulePreferences(MemberId);
CREATE INDEX IX_MemberSchedulePreferences_DayOfWeek ON MemberSchedulePreferences(DayOfWeek);
CREATE INDEX IX_MemberSchedulePreferences_IsActive ON MemberSchedulePreferences(IsActive);

PRINT '  ✓ MemberSchedulePreferences table created';
GO

PRINT 'All 12 tables created successfully with proper foreign keys and indexes';
GO

-- =============================================
-- SECTION 4: CREATE STORED PROCEDURES
-- =============================================

PRINT 'Creating stored procedures...';
GO

-- sp_AuditLog_Create
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
    
    BEGIN TRY
        INSERT INTO AuditLogs (TableName, RecordId, [Action], UserId, Username, OldValues, NewValues, IpAddress, ChangedAt, CreatedAt, IsDeleted)
        VALUES (@TableName, @RecordId, @Action, @UserId, @Username, @OldValues, @NewValues, @IpAddress, GETDATE(), GETDATE(), 0);
        
        RETURN SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '  ✓ sp_AuditLog_Create created';
GO

-- sp_AuditLog_GetByRecord
CREATE PROCEDURE sp_AuditLog_GetByRecord
    @TableName NVARCHAR(100),
    @RecordId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
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
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '  ✓ sp_AuditLog_GetByRecord created';
GO

PRINT 'All stored procedures created successfully (2 total)';
GO

-- =============================================
-- SECTION 5: INSERT SEED DATA
-- =============================================

PRINT 'Inserting seed data...';
GO

-- Correct BCrypt hash for password 'password' with workFactor 11
DECLARE @CorrectHash NVARCHAR(255) = N'$2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq';

-- 1. INSERT USERS (Admin + Trainers + Members)
PRINT '  Inserting Users...';

-- Admin user (ID will be 1)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'admin', @CorrectHash, N'Quản Trị Viên', N'admin@gymmanagement.vn', N'Admin', 1, GETDATE(), GETDATE(), 0);

-- Trainer users (IDs will be 2-6)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'trainer1', @CorrectHash, N'Nguyễn Văn An', N'an.nguyen@gymmanagement.vn', N'Trainer', 1, GETDATE(), GETDATE(), 0),
(N'trainer2', @CorrectHash, N'Trần Thị Bình', N'binh.tran@gymmanagement.vn', N'Trainer', 1, GETDATE(), GETDATE(), 0),
(N'trainer3', @CorrectHash, N'Lê Minh Cường', N'cuong.le@gymmanagement.vn', N'Trainer', 1, GETDATE(), GETDATE(), 0),
(N'trainer4', @CorrectHash, N'Phạm Thu Duyên', N'duyen.pham@gymmanagement.vn', N'Trainer', 1, GETDATE(), GETDATE(), 0),
(N'trainer5', @CorrectHash, N'Hoàng Quốc Huy', N'huy.hoang@gymmanagement.vn', N'Trainer', 1, GETDATE(), GETDATE(), 0);

-- Member users (IDs will be 7-26)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'member01', @CorrectHash, N'Nguyễn Thị Mai', N'mai.nguyen@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member02', @CorrectHash, N'Trần Văn Nam', N'nam.tran@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member03', @CorrectHash, N'Lê Thị Oanh', N'oanh.le@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member04', @CorrectHash, N'Phạm Văn Phúc', N'phuc.pham@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member05', @CorrectHash, N'Hoàng Thị Quỳnh', N'quynh.hoang@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member06', @CorrectHash, N'Vũ Văn Rồng', N'rong.vu@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member07', @CorrectHash, N'Đỗ Thị Sương', N'suong.do@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member08', @CorrectHash, N'Bùi Văn Tài', N'tai.bui@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member09', @CorrectHash, N'Ngô Thị Uyên', N'uyen.ngo@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member10', @CorrectHash, N'Đinh Văn Vinh', N'vinh.dinh@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member11', @CorrectHash, N'Đặng Thị Xuân', N'xuan.dang@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member12', @CorrectHash, N'Cao Văn Yên', N'yen.cao@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member13', @CorrectHash, N'Lưu Thị Ánh', N'anh.luu@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member14', @CorrectHash, N'Dương Văn Bảo', N'bao.duong@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member15', @CorrectHash, N'Phan Thị Chi', N'chi.phan@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member16', @CorrectHash, N'Võ Văn Đức', N'duc.vo@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member17', @CorrectHash, N'Trương Thị Em', N'em.truong@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member18', @CorrectHash, N'Hồ Văn Phong', N'phong.ho@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member19', @CorrectHash, N'Tô Thị Giang', N'giang.to@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0),
(N'member20', @CorrectHash, N'Lý Văn Hào', N'hao.ly@gmail.com', N'Member', 1, GETDATE(), GETDATE(), 0);

PRINT '    ✓ 26 Users inserted (1 Admin, 5 Trainers, 20 Members)';

-- 2. INSERT TRAINERS (matching trainer users)
PRINT '  Inserting Trainers...';

INSERT INTO Trainers (FullName, Email, Phone, Specialization, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Nguyễn Văn An', N'an.nguyen@gymmanagement.vn', N'0901234567', N'Gym & Fitness', GETDATE(), GETDATE(), 0),
(N'Trần Thị Bình', N'binh.tran@gymmanagement.vn', N'0901234568', N'Yoga & Pilates', GETDATE(), GETDATE(), 0),
(N'Lê Minh Cường', N'cuong.le@gymmanagement.vn', N'0901234569', N'Cardio & HIIT', GETDATE(), GETDATE(), 0),
(N'Phạm Thu Duyên', N'duyen.pham@gymmanagement.vn', N'0901234570', N'Aerobic & Dance', GETDATE(), GETDATE(), 0),
(N'Hoàng Quốc Huy', N'huy.hoang@gymmanagement.vn', N'0901234571', N'Boxing & Martial Arts', GETDATE(), GETDATE(), 0);

PRINT '    ✓ 5 Trainers inserted';

-- 3. INSERT MEMBERS (matching member users + trainer users for check-in support)
PRINT '  Inserting Members...';

-- Member-role users (MemberId 1-20)
INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Nguyễn Thị Mai', N'mai.nguyen@gmail.com', N'0912345601', N'1995-03-15', N'M000001', GETDATE(), GETDATE(), 0),
(N'Trần Văn Nam', N'nam.tran@gmail.com', N'0912345602', N'1992-07-20', N'M000002', GETDATE(), GETDATE(), 0),
(N'Lê Thị Oanh', N'oanh.le@gmail.com', N'0912345603', N'1998-11-05', N'M000003', GETDATE(), GETDATE(), 0),
(N'Phạm Văn Phúc', N'phuc.pham@gmail.com', N'0912345604', N'1990-01-10', N'M000004', GETDATE(), GETDATE(), 0),
(N'Hoàng Thị Quỳnh', N'quynh.hoang@gmail.com', N'0912345605', N'1997-05-25', N'M000005', GETDATE(), GETDATE(), 0),
(N'Vũ Văn Rồng', N'rong.vu@gmail.com', N'0912345606', N'1993-09-30', N'M000006', GETDATE(), GETDATE(), 0),
(N'Đỗ Thị Sương', N'suong.do@gmail.com', N'0912345607', N'1996-02-14', N'M000007', GETDATE(), GETDATE(), 0),
(N'Bùi Văn Tài', N'tai.bui@gmail.com', N'0912345608', N'1991-06-18', N'M000008', GETDATE(), GETDATE(), 0),
(N'Ngô Thị Uyên', N'uyen.ngo@gmail.com', N'0912345609', N'1999-12-22', N'M000009', GETDATE(), GETDATE(), 0),
(N'Đinh Văn Vinh', N'vinh.dinh@gmail.com', N'0912345610', N'1994-04-08', N'M000010', GETDATE(), GETDATE(), 0),
(N'Đặng Thị Xuân', N'xuan.dang@gmail.com', N'0912345611', N'1995-08-12', N'M000011', GETDATE(), GETDATE(), 0),
(N'Cao Văn Yên', N'yen.cao@gmail.com', N'0912345612', N'1992-10-28', N'M000012', GETDATE(), GETDATE(), 0),
(N'Lưu Thị Ánh', N'anh.luu@gmail.com', N'0912345613', N'1997-03-03', N'M000013', GETDATE(), GETDATE(), 0),
(N'Dương Văn Bảo', N'bao.duong@gmail.com', N'0912345614', N'1990-07-17', N'M000014', GETDATE(), GETDATE(), 0),
(N'Phan Thị Chi', N'chi.phan@gmail.com', N'0912345615', N'1998-11-21', N'M000015', GETDATE(), GETDATE(), 0),
(N'Võ Văn Đức', N'duc.vo@gmail.com', N'0912345616', N'1993-01-26', N'M000016', GETDATE(), GETDATE(), 0),
(N'Trương Thị Em', N'em.truong@gmail.com', N'0912345617', N'1996-05-09', N'M000017', GETDATE(), GETDATE(), 0),
(N'Hồ Văn Phong', N'phong.ho@gmail.com', N'0912345618', N'1991-09-13', N'M000018', GETDATE(), GETDATE(), 0),
(N'Tô Thị Giang', N'giang.to@gmail.com', N'0912345619', N'1999-02-27', N'M000019', GETDATE(), GETDATE(), 0),
(N'Lý Văn Hào', N'hao.ly@gmail.com', N'0912345620', N'1994-06-04', N'M000020', GETDATE(), GETDATE(), 0);

-- Trainer-role users ALSO need Member records for check-in functionality (MemberId 21-25)
INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Nguyễn Văn An', N'an.nguyen@gymmanagement.vn', N'0901234567', N'1988-03-12', N'M000021', GETDATE(), GETDATE(), 0),
(N'Trần Thị Bình', N'binh.tran@gymmanagement.vn', N'0901234568', N'1990-07-25', N'M000022', GETDATE(), GETDATE(), 0),
(N'Lê Minh Cường', N'cuong.le@gymmanagement.vn', N'0901234569', N'1985-11-08', N'M000023', GETDATE(), GETDATE(), 0),
(N'Phạm Thu Duyên', N'duyen.pham@gymmanagement.vn', N'0901234570', N'1992-04-18', N'M000024', GETDATE(), GETDATE(), 0),
(N'Hoàng Quốc Huy', N'huy.hoang@gymmanagement.vn', N'0901234571', N'1987-09-30', N'M000025', GETDATE(), GETDATE(), 0);

PRINT '    ✓ 25 Members inserted (20 Member-role + 5 Trainer-role for check-in support)';

-- 4. INSERT FACILITIES
PRINT '  Inserting Facilities...';

INSERT INTO Facilities (Name, Description, Status, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Phòng Gym Tầng 1', N'Phòng tập gym chính với đầy đủ thiết bị hiện đại', N'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Yoga', N'Phòng tập yoga yên tĩnh, thoáng mát', N'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Cardio', N'Phòng tập cardio với máy chạy bộ, xe đạp', N'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Aerobic', N'Phòng tập aerobic rộng rãi với hệ thống âm thanh tốt', N'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Boxing', N'Phòng tập boxing với bao cát và sàn đấu', N'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Gym Tầng 2', N'Phòng gym phụ với thiết bị tạ tự do', N'Available', GETDATE(), GETDATE(), 0),
(N'Sân Tennis', N'Sân tennis ngoài trời', N'Maintenance', GETDATE(), GETDATE(), 0),
(N'Phòng Pilates', N'Phòng tập pilates chuyên nghiệp', N'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Spinning', N'Phòng tập spinning với 20 xe đạp', N'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Đa Năng', N'Phòng đa năng cho các lớp học nhóm', N'Available', GETDATE(), GETDATE(), 0);

PRINT '    ✓ 10 Facilities inserted';

-- 5. INSERT MEMBERSHIPS (only for Member-role users, not for Trainers who are employees)
PRINT '  Inserting Memberships...';

INSERT INTO Memberships (MemberId, PackageName, Price, StartDate, EndDate, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, N'Gói Tháng', 500000.00, N'2025-01-01', N'2025-02-01', GETDATE(), GETDATE(), 0),
(2, N'Gói Quý', 1350000.00, N'2025-01-05', N'2025-04-05', GETDATE(), GETDATE(), 0),
(3, N'Gói Năm', 5000000.00, N'2025-01-10', N'2026-01-10', GETDATE(), GETDATE(), 0),
(4, N'Gói Tháng', 500000.00, N'2025-01-15', N'2025-02-15', GETDATE(), GETDATE(), 0),
(5, N'Gói 6 Tháng', 2700000.00, N'2025-02-01', N'2025-08-01', GETDATE(), GETDATE(), 0),
(6, N'Gói Tháng', 500000.00, N'2025-02-05', N'2025-03-05', GETDATE(), GETDATE(), 0),
(7, N'Gói Quý', 1350000.00, N'2025-02-10', N'2025-05-10', GETDATE(), GETDATE(), 0),
(8, N'Gói Năm', 5000000.00, N'2025-02-15', N'2026-02-15', GETDATE(), GETDATE(), 0),
(9, N'Gói Tháng', 500000.00, N'2025-03-01', N'2025-04-01', GETDATE(), GETDATE(), 0),
(10, N'Gói 6 Tháng', 2700000.00, N'2025-03-05', N'2025-09-05', GETDATE(), GETDATE(), 0),
(11, N'Gói Quý', 1350000.00, N'2025-03-10', N'2025-06-10', GETDATE(), GETDATE(), 0),
(12, N'Gói Tháng', 500000.00, N'2025-03-15', N'2025-04-15', GETDATE(), GETDATE(), 0),
(13, N'Gói Năm', 5000000.00, N'2025-04-01', N'2026-04-01', GETDATE(), GETDATE(), 0),
(14, N'Gói Quý', 1350000.00, N'2025-04-05', N'2025-07-05', GETDATE(), GETDATE(), 0),
(15, N'Gói 6 Tháng', 2700000.00, N'2025-04-10', N'2025-10-10', GETDATE(), GETDATE(), 0),
(16, N'Gói Tháng', 500000.00, N'2025-04-15', N'2025-05-15', GETDATE(), GETDATE(), 0),
(17, N'Gói Quý', 1350000.00, N'2025-05-01', N'2025-08-01', GETDATE(), GETDATE(), 0),
(18, N'Gói Năm', 5000000.00, N'2025-05-05', N'2026-05-05', GETDATE(), GETDATE(), 0),
(19, N'Gói Tháng', 500000.00, N'2025-05-10', N'2025-06-10', GETDATE(), GETDATE(), 0),
(20, N'Gói 6 Tháng', 2700000.00, N'2025-05-15', N'2025-11-15', GETDATE(), GETDATE(), 0);

PRINT '    ✓ 20 Memberships inserted';

-- 6. INSERT SCHEDULES (created by trainers)
PRINT '  Inserting Schedules...';

INSERT INTO Schedules (TrainerId, FacilityId, ClassName, StartTime, EndTime, MaxCapacity, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, 1, N'Gym Buổi Sáng', N'2025-01-06 06:00:00', N'2025-01-06 07:30:00', 20, GETDATE(), GETDATE(), 0),
(1, 1, N'Gym Buổi Tối', N'2025-01-06 18:00:00', N'2025-01-06 19:30:00', 20, GETDATE(), GETDATE(), 0),
(2, 2, N'Yoga Cơ Bản', N'2025-01-07 07:00:00', N'2025-01-07 08:00:00', 15, GETDATE(), GETDATE(), 0),
(2, 2, N'Yoga Nâng Cao', N'2025-01-07 19:00:00', N'2025-01-07 20:00:00', 15, GETDATE(), GETDATE(), 0),
(3, 3, N'Cardio Cường Độ Cao', N'2025-01-08 06:30:00', N'2025-01-08 07:30:00', 25, GETDATE(), GETDATE(), 0),
(3, 3, N'Cardio Buổi Chiều', N'2025-01-08 17:00:00', N'2025-01-08 18:00:00', 25, GETDATE(), GETDATE(), 0),
(4, 4, N'Aerobic Sáng', N'2025-01-09 06:00:00', N'2025-01-09 07:00:00', 30, GETDATE(), GETDATE(), 0),
(4, 4, N'Aerobic Tối', N'2025-01-09 18:30:00', N'2025-01-09 19:30:00', 30, GETDATE(), GETDATE(), 0),
(5, 5, N'Boxing Cơ Bản', N'2025-01-10 07:00:00', N'2025-01-10 08:30:00', 12, GETDATE(), GETDATE(), 0),
(5, 5, N'Boxing Nâng Cao', N'2025-01-10 19:00:00', N'2025-01-10 20:30:00', 12, GETDATE(), GETDATE(), 0),
(1, 6, N'Tập Tạ Tự Do', N'2025-01-13 08:00:00', N'2025-01-13 09:30:00', 15, GETDATE(), GETDATE(), 0),
(2, 8, N'Pilates Buổi Sáng', N'2025-01-14 07:30:00', N'2025-01-14 08:30:00', 12, GETDATE(), GETDATE(), 0),
(3, 9, N'Spinning Buổi Sáng', N'2025-01-15 06:00:00', N'2025-01-15 07:00:00', 20, GETDATE(), GETDATE(), 0),
(3, 9, N'Spinning Buổi Tối', N'2025-01-15 18:00:00', N'2025-01-15 19:00:00', 20, GETDATE(), GETDATE(), 0),
(4, 10, N'Dance Fitness', N'2025-01-16 19:00:00', N'2025-01-16 20:00:00', 25, GETDATE(), GETDATE(), 0),
(1, 1, N'Gym Thứ 7', N'2025-01-17 08:00:00', N'2025-01-17 10:00:00', 25, GETDATE(), GETDATE(), 0),
(2, 2, N'Yoga Cuối Tuần', N'2025-01-18 09:00:00', N'2025-01-18 10:30:00', 20, GETDATE(), GETDATE(), 0),
(3, 3, N'Cardio Chủ Nhật', N'2025-01-18 10:00:00', N'2025-01-18 11:00:00', 30, GETDATE(), GETDATE(), 0),
(4, 4, N'Zumba Cuối Tuần', N'2025-01-18 17:00:00', N'2025-01-18 18:00:00', 35, GETDATE(), GETDATE(), 0),
(5, 5, N'Boxing Chủ Nhật', N'2025-01-18 08:00:00', N'2025-01-18 09:30:00', 15, GETDATE(), GETDATE(), 0);

PRINT '    ✓ 20 Schedules inserted';

-- 7. INSERT SESSIONS (Member registrations for schedules)
PRINT '  Inserting Sessions...';

INSERT INTO Sessions (ScheduleId, MemberId, RegistrationDate, Status, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, 1, N'2025-01-02', N'Attended', GETDATE(), GETDATE(), 0),
(1, 2, N'2025-01-02', N'Attended', GETDATE(), GETDATE(), 0),
(1, 3, N'2025-01-02', N'Registered', GETDATE(), GETDATE(), 0),
(3, 4, N'2025-01-03', N'Attended', GETDATE(), GETDATE(), 0),
(3, 5, N'2025-01-03', N'Attended', GETDATE(), GETDATE(), 0),
(5, 6, N'2025-01-04', N'Registered', GETDATE(), GETDATE(), 0),
(5, 7, N'2025-01-04', N'Attended', GETDATE(), GETDATE(), 0),
(7, 8, N'2025-01-05', N'Attended', GETDATE(), GETDATE(), 0),
(7, 9, N'2025-01-05', N'Cancelled', GETDATE(), GETDATE(), 0),
(9, 10, N'2025-01-06', N'Attended', GETDATE(), GETDATE(), 0),
(2, 11, N'2025-01-03', N'Attended', GETDATE(), GETDATE(), 0),
(2, 12, N'2025-01-03', N'Registered', GETDATE(), GETDATE(), 0),
(4, 13, N'2025-01-04', N'Attended', GETDATE(), GETDATE(), 0),
(6, 14, N'2025-01-05', N'Attended', GETDATE(), GETDATE(), 0),
(8, 15, N'2025-01-06', N'Registered', GETDATE(), GETDATE(), 0),
(10, 16, N'2025-01-07', N'Attended', GETDATE(), GETDATE(), 0),
(11, 17, N'2025-01-08', N'Attended', GETDATE(), GETDATE(), 0),
(12, 18, N'2025-01-09', N'Registered', GETDATE(), GETDATE(), 0),
(13, 19, N'2025-01-10', N'Attended', GETDATE(), GETDATE(), 0),
(14, 20, N'2025-01-11', N'Attended', GETDATE(), GETDATE(), 0),
(15, 1, N'2025-01-12', N'Registered', GETDATE(), GETDATE(), 0),
(16, 2, N'2025-01-13', N'Attended', GETDATE(), GETDATE(), 0),
(17, 3, N'2025-01-14', N'Attended', GETDATE(), GETDATE(), 0),
(18, 4, N'2025-01-15', N'Cancelled', GETDATE(), GETDATE(), 0),
(19, 5, N'2025-01-16', N'Attended', GETDATE(), GETDATE(), 0),
(20, 6, N'2025-01-17', N'Attended', GETDATE(), GETDATE(), 0);

PRINT '    ✓ 26 Sessions inserted';

-- 8. INSERT CHECKINS (both Member-role and Trainer-role users, sorted by CheckinTime ASC)
PRINT '  Inserting Checkins...';

INSERT INTO Checkins (MemberId, CheckinTime, CheckoutTime, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
-- Member-role check-ins
(1, N'2025-01-06 06:00:00', N'2025-01-06 07:45:00', GETDATE(), GETDATE(), 0),
(2, N'2025-01-06 06:05:00', N'2025-01-06 07:50:00', GETDATE(), GETDATE(), 0),
(3, N'2025-01-06 06:10:00', NULL, GETDATE(), GETDATE(), 0),
(4, N'2025-01-07 07:00:00', N'2025-01-07 08:15:00', GETDATE(), GETDATE(), 0),
(5, N'2025-01-07 07:05:00', N'2025-01-07 08:20:00', GETDATE(), GETDATE(), 0),
(6, N'2025-01-08 06:30:00', N'2025-01-08 07:45:00', GETDATE(), GETDATE(), 0),
(7, N'2025-01-08 06:35:00', N'2025-01-08 07:50:00', GETDATE(), GETDATE(), 0),
(8, N'2025-01-09 06:00:00', N'2025-01-09 07:15:00', GETDATE(), GETDATE(), 0),
(10, N'2025-01-10 07:00:00', N'2025-01-10 08:45:00', GETDATE(), GETDATE(), 0),
(11, N'2025-01-06 18:00:00', N'2025-01-06 19:45:00', GETDATE(), GETDATE(), 0),
(12, N'2025-01-06 18:05:00', NULL, GETDATE(), GETDATE(), 0),
(13, N'2025-01-07 19:00:00', N'2025-01-07 20:15:00', GETDATE(), GETDATE(), 0),
(14, N'2025-01-08 17:00:00', N'2025-01-08 18:15:00', GETDATE(), GETDATE(), 0),
(15, N'2025-01-09 18:30:00', NULL, GETDATE(), GETDATE(), 0),
(16, N'2025-01-10 19:00:00', N'2025-01-10 20:45:00', GETDATE(), GETDATE(), 0),
(17, N'2025-01-13 08:00:00', N'2025-01-13 09:45:00', GETDATE(), GETDATE(), 0),
(18, N'2025-01-14 07:30:00', NULL, GETDATE(), GETDATE(), 0),
(19, N'2025-01-15 06:00:00', N'2025-01-15 07:15:00', GETDATE(), GETDATE(), 0),
(20, N'2025-01-16 19:00:00', N'2025-01-16 20:15:00', GETDATE(), GETDATE(), 0),
-- Trainer-role check-ins (MemberId 21-25) - Trainers check in as employees
(21, N'2025-01-06 05:45:00', N'2025-01-06 14:00:00', GETDATE(), GETDATE(), 0),
(22, N'2025-01-07 06:30:00', N'2025-01-07 15:00:00', GETDATE(), GETDATE(), 0),
(23, N'2025-01-08 06:15:00', N'2025-01-08 14:30:00', GETDATE(), GETDATE(), 0),
(24, N'2025-01-09 05:50:00', N'2025-01-09 14:00:00', GETDATE(), GETDATE(), 0),
(25, N'2025-01-10 06:45:00', N'2025-01-10 15:30:00', GETDATE(), GETDATE(), 0),
(21, N'2025-01-13 07:45:00', N'2025-01-13 16:00:00', GETDATE(), GETDATE(), 0),
(22, N'2025-01-14 07:15:00', N'2025-01-14 15:30:00', GETDATE(), GETDATE(), 0),
(23, N'2025-01-15 05:50:00', N'2025-01-15 14:00:00', GETDATE(), GETDATE(), 0),
(24, N'2025-01-16 18:45:00', N'2025-01-16 21:00:00', GETDATE(), GETDATE(), 0),
(25, N'2025-01-18 07:50:00', NULL, GETDATE(), GETDATE(), 0);

PRINT '    ✓ 29 Checkins inserted (19 Member-role + 10 Trainer-role check-ins)';

-- 9. INSERT INVOICES
PRINT '  Inserting Invoices...';

INSERT INTO Invoices (MemberId, MembershipId, InvoiceDate, DueDate, TotalAmount, Status, Description, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, 1, N'2025-01-01', N'2025-01-08', 500000.00, N'Paid', N'Hóa đơn gói tháng - Nguyễn Thị Mai', GETDATE(), GETDATE(), 0),
(2, 2, N'2025-01-05', N'2025-01-12', 1350000.00, N'Paid', N'Hóa đơn gói quý - Trần Văn Nam', GETDATE(), GETDATE(), 0),
(3, 3, N'2025-01-10', N'2025-01-17', 5000000.00, N'Paid', N'Hóa đơn gói năm - Lê Thị Oanh', GETDATE(), GETDATE(), 0),
(4, 4, N'2025-01-15', N'2025-01-22', 500000.00, N'Paid', N'Hóa đơn gói tháng - Phạm Văn Phúc', GETDATE(), GETDATE(), 0),
(5, 5, N'2025-02-01', N'2025-02-08', 2700000.00, N'Paid', N'Hóa đơn gói 6 tháng - Hoàng Thị Quỳnh', GETDATE(), GETDATE(), 0),
(6, 6, N'2025-02-05', N'2025-02-12', 500000.00, N'Pending', N'Hóa đơn gói tháng - Vũ Văn Rồng', GETDATE(), GETDATE(), 0),
(7, 7, N'2025-02-10', N'2025-02-17', 1350000.00, N'Paid', N'Hóa đơn gói quý - Đỗ Thị Sương', GETDATE(), GETDATE(), 0),
(8, 8, N'2025-02-15', N'2025-02-22', 5000000.00, N'Paid', N'Hóa đơn gói năm - Bùi Văn Tài', GETDATE(), GETDATE(), 0),
(9, 9, N'2025-03-01', N'2025-03-08', 500000.00, N'Pending', N'Hóa đơn gói tháng - Ngô Thị Uyên', GETDATE(), GETDATE(), 0),
(10, 10, N'2025-03-05', N'2025-03-12', 2700000.00, N'Paid', N'Hóa đơn gói 6 tháng - Đinh Văn Vinh', GETDATE(), GETDATE(), 0),
(11, 11, N'2025-03-10', N'2025-03-17', 1350000.00, N'Paid', N'Hóa đơn gói quý - Đặng Thị Xuân', GETDATE(), GETDATE(), 0),
(12, 12, N'2025-03-15', N'2025-03-22', 500000.00, N'Pending', N'Hóa đơn gói tháng - Cao Văn Yên', GETDATE(), GETDATE(), 0),
(13, 13, N'2025-04-01', N'2025-04-08', 5000000.00, N'Paid', N'Hóa đơn gói năm - Lưu Thị Ánh', GETDATE(), GETDATE(), 0),
(14, 14, N'2025-04-05', N'2025-04-12', 1350000.00, N'Paid', N'Hóa đơn gói quý - Dương Văn Bảo', GETDATE(), GETDATE(), 0),
(15, 15, N'2025-04-10', N'2025-04-17', 2700000.00, N'Pending', N'Hóa đơn gói 6 tháng - Phan Thị Chi', GETDATE(), GETDATE(), 0),
(16, 16, N'2025-04-15', N'2025-04-22', 500000.00, N'Paid', N'Hóa đơn gói tháng - Võ Văn Đức', GETDATE(), GETDATE(), 0),
(17, 17, N'2025-05-01', N'2025-05-08', 1350000.00, N'Paid', N'Hóa đơn gói quý - Trương Thị Em', GETDATE(), GETDATE(), 0),
(18, 18, N'2025-05-05', N'2025-05-12', 5000000.00, N'Paid', N'Hóa đơn gói năm - Hồ Văn Phong', GETDATE(), GETDATE(), 0),
(19, 19, N'2025-05-10', N'2025-05-17', 500000.00, N'Pending', N'Hóa đơn gói tháng - Tô Thị Giang', GETDATE(), GETDATE(), 0),
(20, 20, N'2025-05-15', N'2025-05-22', 2700000.00, N'Paid', N'Hóa đơn gói 6 tháng - Lý Văn Hào', GETDATE(), GETDATE(), 0);

PRINT '    ✓ 20 Invoices inserted';

-- 10. INSERT PAYMENTS
PRINT '  Inserting Payments...';

INSERT INTO Payments (InvoiceId, MemberId, Amount, PaymentMethod, PaymentDate, TransactionId, Status, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, 1, 500000.00, N'Cash', N'2025-01-01', NULL, N'Completed', GETDATE(), GETDATE(), 0),
(2, 2, 1350000.00, N'BankTransfer', N'2025-01-05', N'BT20250105001', N'Completed', GETDATE(), GETDATE(), 0),
(3, 3, 5000000.00, N'Card', N'2025-01-10', N'CARD20250110001', N'Completed', GETDATE(), GETDATE(), 0),
(4, 4, 500000.00, N'Cash', N'2025-01-15', NULL, N'Completed', GETDATE(), GETDATE(), 0),
(5, 5, 2700000.00, N'BankTransfer', N'2025-02-01', N'BT20250201001', N'Completed', GETDATE(), GETDATE(), 0),
(7, 7, 1350000.00, N'Card', N'2025-02-10', N'CARD20250210001', N'Completed', GETDATE(), GETDATE(), 0),
(8, 8, 5000000.00, N'BankTransfer', N'2025-02-15', N'BT20250215001', N'Completed', GETDATE(), GETDATE(), 0),
(10, 10, 2700000.00, N'Cash', N'2025-03-05', NULL, N'Completed', GETDATE(), GETDATE(), 0),
(11, 11, 1350000.00, N'BankTransfer', N'2025-03-10', N'BT20250310001', N'Completed', GETDATE(), GETDATE(), 0),
(13, 13, 5000000.00, N'Card', N'2025-04-01', N'CARD20250401001', N'Completed', GETDATE(), GETDATE(), 0),
(14, 14, 1350000.00, N'Cash', N'2025-04-05', NULL, N'Completed', GETDATE(), GETDATE(), 0),
(16, 16, 500000.00, N'BankTransfer', N'2025-04-15', N'BT20250415001', N'Completed', GETDATE(), GETDATE(), 0),
(17, 17, 1350000.00, N'Card', N'2025-05-01', N'CARD20250501001', N'Completed', GETDATE(), GETDATE(), 0),
(18, 18, 5000000.00, N'BankTransfer', N'2025-05-05', N'BT20250505001', N'Completed', GETDATE(), GETDATE(), 0),
(20, 20, 2700000.00, N'Cash', N'2025-05-15', NULL, N'Completed', GETDATE(), GETDATE(), 0);

PRINT '    ✓ 15 Payments inserted';

-- 11. INSERT MEMBER SCHEDULE PREFERENCES
PRINT '  Inserting MemberSchedulePreferences...';

INSERT INTO MemberSchedulePreferences (MemberId, DayOfWeek, StartTime, EndTime, IsActive, CreatedAt, UpdatedAt)
VALUES 
(1, 1, N'06:00:00', N'08:00:00', 1, GETDATE(), GETDATE()),
(2, 1, N'18:00:00', N'20:00:00', 1, GETDATE(), GETDATE()),
(3, 2, N'07:00:00', N'09:00:00', 1, GETDATE(), GETDATE()),
(4, 3, N'06:00:00', N'08:00:00', 1, GETDATE(), GETDATE()),
(5, 4, N'19:00:00', N'21:00:00', 1, GETDATE(), GETDATE()),
(6, 5, N'07:00:00', N'09:00:00', 1, GETDATE(), GETDATE()),
(7, 6, N'08:00:00', N'10:00:00', 1, GETDATE(), GETDATE()),
(8, 0, N'09:00:00', N'11:00:00', 1, GETDATE(), GETDATE()),
(9, 1, N'17:00:00', N'19:00:00', 1, GETDATE(), GETDATE()),
(10, 2, N'18:00:00', N'20:00:00', 1, GETDATE(), GETDATE());

PRINT '    ✓ 10 MemberSchedulePreferences inserted';

-- 12. INSERT AUDIT LOGS (Sample data for testing)
PRINT '  Inserting AuditLogs...';

INSERT INTO AuditLogs (TableName, RecordId, [Action], UserId, Username, OldValues, NewValues, ChangedAt, IpAddress, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Users', 1, N'INSERT', 1, N'admin', NULL, N'{"Username":"admin","Role":"Admin"}', GETDATE(), N'127.0.0.1', GETDATE(), GETDATE(), 0),
(N'Members', 1, N'INSERT', 1, N'admin', NULL, N'{"FullName":"Nguyễn Thị Mai","QRCode":"M000001"}', GETDATE(), N'127.0.0.1', GETDATE(), GETDATE(), 0),
(N'Memberships', 1, N'INSERT', 1, N'admin', NULL, N'{"MemberId":1,"PackageName":"Gói Tháng","Price":500000}', GETDATE(), N'127.0.0.1', GETDATE(), GETDATE(), 0),
(N'Invoices', 1, N'INSERT', 1, N'admin', NULL, N'{"InvoiceId":1,"TotalAmount":500000,"Status":"Paid"}', GETDATE(), N'127.0.0.1', GETDATE(), GETDATE(), 0),
(N'Payments', 1, N'INSERT', 1, N'admin', NULL, N'{"PaymentId":1,"Amount":500000,"PaymentMethod":"Cash"}', GETDATE(), N'127.0.0.1', GETDATE(), GETDATE(), 0);

PRINT '    ✓ 5 AuditLogs inserted';

PRINT 'All seed data inserted successfully';
GO

-- =============================================
-- SECTION 6: VERIFICATION & SUMMARY
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'DATABASE CREATION COMPLETED SUCCESSFULLY';
PRINT '=============================================';
PRINT '';
PRINT 'Database Summary:';
PRINT '  Database: GymDb (Vietnamese_CI_AS collation)';
PRINT '  Tables: 12 total';
PRINT '  Stored Procedures: 2 (sp_AuditLog_Create, sp_AuditLog_GetByRecord)';
PRINT '  Indexes: All tables indexed properly';
PRINT '';
PRINT 'Seed Data Summary:';
PRINT '  - Users: 26 (1 Admin, 5 Trainers, 20 Members)';
PRINT '  - Trainers: 5';
PRINT '  - Members: 25 (20 Member-role + 5 Trainer-role for check-in)';
PRINT '  - Facilities: 10';
PRINT '  - Memberships: 20 (Member-role users only)';
PRINT '  - Schedules: 20 (training classes)';
PRINT '  - Sessions: 26 (member registrations)';
PRINT '  - Checkins: 29 (19 Member-role + 10 Trainer-role)';
PRINT '  - Invoices: 20';
PRINT '  - Payments: 15';
PRINT '  - MemberSchedulePreferences: 10';
PRINT '  - AuditLogs: 5';
PRINT '';
PRINT 'Test Credentials (all passwords: password):';
PRINT '  Admin:    admin / password';
PRINT '  Trainer:  trainer1 / password (also: trainer2-trainer5)';
PRINT '  Member:   member01 / password (also: member02-member20)';
PRINT '';
PRINT 'Key Features:';
PRINT '  ✓ All Vietnamese text uses NVARCHAR with N-prefix';
PRINT '  ✓ Trainers have BOTH Trainer AND Member records for check-in';
PRINT '  ✓ Check-ins support both Members and Trainers';
PRINT '  ✓ Role-switch ready (auto-create missing records)';
PRINT '  ✓ Proper foreign key constraints and indexes';
PRINT '  ✓ Stored procedures for audit logging';
PRINT '  ✓ Soft delete pattern (IsDeleted, DeletedAt)';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Update appsettings.json connection string to: Server=.;Database=GymDb;Trusted_Connection=True;';
PRINT '  2. Run dotnet build to verify compilation';
PRINT '  3. Test login with admin/password';
PRINT '  4. Verify trainer check-in functionality';
PRINT '';

-- Verification Queries
SELECT 'Users' AS TableName, COUNT(*) AS RowCount FROM Users WHERE IsDeleted = 0
UNION ALL
SELECT 'Trainers', COUNT(*) FROM Trainers WHERE IsDeleted = 0
UNION ALL
SELECT 'Members', COUNT(*) FROM Members WHERE IsDeleted = 0
UNION ALL
SELECT 'Facilities', COUNT(*) FROM Facilities WHERE IsDeleted = 0
UNION ALL
SELECT 'Memberships', COUNT(*) FROM Memberships WHERE IsDeleted = 0
UNION ALL
SELECT 'Schedules', COUNT(*) FROM Schedules WHERE IsDeleted = 0
UNION ALL
SELECT 'Sessions', COUNT(*) FROM Sessions WHERE IsDeleted = 0
UNION ALL
SELECT 'Checkins', COUNT(*) FROM Checkins WHERE IsDeleted = 0
UNION ALL
SELECT 'Invoices', COUNT(*) FROM Invoices WHERE IsDeleted = 0
UNION ALL
SELECT 'Payments', COUNT(*) FROM Payments WHERE IsDeleted = 0
UNION ALL
SELECT 'MemberSchedulePreferences', COUNT(*) FROM MemberSchedulePreferences WHERE IsActive = 1
UNION ALL
SELECT 'AuditLogs', COUNT(*) FROM AuditLogs WHERE IsDeleted = 0;

GO
