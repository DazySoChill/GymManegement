-- =============================================
-- FILE: 01_CREATE_TABLES.sql
-- PURPOSE: Create all database tables with constraints and indexes
-- DESCRIPTION: Creates 12 tables for the gym management system with
--              proper foreign keys, constraints, indexes, and Vietnamese support
-- =============================================

USE GymDb;
GO

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
