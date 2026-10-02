-- ============================================================
-- FILE: 01_Schema.sql
-- Mô tả: Schema đơn giản, tương thích C# hiện tại
-- Chạy lần 1 để tạo DB + bảng. An toàn re-run (IF NOT EXISTS).
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'GymDb')
    CREATE DATABASE GymDb;
GO

USE GymDb;
GO

-- ============================================================
-- 1. Members (hội viên)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Members' AND xtype='U')
CREATE TABLE Members (
    MemberId        INT             IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Phone           NVARCHAR(20)    NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    DateOfBirth     DATE            NOT NULL,
    JoinDate        DATE            NOT NULL DEFAULT GETDATE(),
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Active'      
                        CHECK (Status IN ('Active','Inactive','Suspended')),
    QRCodeValue     NVARCHAR(50)    NOT NULL UNIQUE
);
GO

-- ============================================================
-- 2. Trainers (huấn luyện viên)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Trainers' AND xtype='U')
CREATE TABLE Trainers (
    TrainerId       INT             IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Phone           NVARCHAR(20)    NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    Specialization  NVARCHAR(100)   NULL
);
GO

-- ============================================================
-- 3. Facilities (phòng/thiết bị)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Facilities' AND xtype='U')
CREATE TABLE Facilities (
    FacilityId      INT             IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(100)   NOT NULL,
    Description     NVARCHAR(500)   NULL,
    IsActive        BIT             NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- 4. Memberships (gói tập)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Memberships' AND xtype='U')
CREATE TABLE Memberships (
    MembershipId    INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL REFERENCES Members(MemberId),
    MembershipType  NVARCHAR(50)    NOT NULL,   -- Monthly | Quarterly | Annual
    Price           DECIMAL(18,2)   NOT NULL,
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Memberships_MemberId' AND object_id = OBJECT_ID('Memberships'))
CREATE INDEX IX_Memberships_MemberId ON Memberships(MemberId);
GO

-- ============================================================
-- 5. Schedules (lịch tập)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Schedules' AND xtype='U')
CREATE TABLE Schedules (
    ScheduleId      INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL REFERENCES Members(MemberId),
    TrainerId       INT             NOT NULL REFERENCES Trainers(TrainerId),
    FacilityId      INT             NOT NULL REFERENCES Facilities(FacilityId),
    StartTime       DATETIME2       NOT NULL,
    EndTime         DATETIME2       NOT NULL
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Schedules_MemberId'   AND object_id = OBJECT_ID('Schedules')) CREATE INDEX IX_Schedules_MemberId   ON Schedules(MemberId);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Schedules_TrainerId'  AND object_id = OBJECT_ID('Schedules')) CREATE INDEX IX_Schedules_TrainerId  ON Schedules(TrainerId);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Schedules_FacilityId' AND object_id = OBJECT_ID('Schedules')) CREATE INDEX IX_Schedules_FacilityId ON Schedules(FacilityId);
GO

-- ============================================================
-- 6. Sessions (buổi tập thực tế)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Sessions' AND xtype='U')
CREATE TABLE Sessions (
    SessionId       INT             IDENTITY(1,1) PRIMARY KEY,
    ScheduleId      INT             NOT NULL REFERENCES Schedules(ScheduleId),
    SessionDate     DATE            NOT NULL,
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Scheduled'  
                        CHECK (Status IN ('Scheduled','Completed','Cancelled'))
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Sessions_ScheduleId' AND object_id = OBJECT_ID('Sessions')) CREATE INDEX IX_Sessions_ScheduleId ON Sessions(ScheduleId);
GO

-- ============================================================
-- 7. Checkins
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Checkins' AND xtype='U')
CREATE TABLE Checkins (
    CheckinId       INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL REFERENCES Members(MemberId),
    SessionId       INT             NOT NULL REFERENCES Sessions(SessionId),
    CheckinTime     DATETIME2       NOT NULL DEFAULT GETDATE(),
    CheckinMethod   NVARCHAR(50)    NOT NULL DEFAULT 'Manual'     -- Manual | QRCode | Card
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkins_MemberId'  AND object_id = OBJECT_ID('Checkins')) CREATE INDEX IX_Checkins_MemberId  ON Checkins(MemberId);
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkins_SessionId' AND object_id = OBJECT_ID('Checkins')) CREATE INDEX IX_Checkins_SessionId ON Checkins(SessionId);
GO

-- ============================================================
-- 8. Invoices (hóa đơn)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Invoices' AND xtype='U')
CREATE TABLE Invoices (
    InvoiceId       INT             IDENTITY(1,1) PRIMARY KEY,
    MemberId        INT             NOT NULL REFERENCES Members(MemberId),
    TotalAmount     DECIMAL(18,2)   NOT NULL,
    InvoiceDate     DATE            NOT NULL DEFAULT GETDATE(),
    DueDate         DATE            NOT NULL,
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Pending'    
                        CHECK (Status IN ('Pending','Paid','Overdue','Cancelled'))
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Invoices_MemberId' AND object_id = OBJECT_ID('Invoices')) CREATE INDEX IX_Invoices_MemberId ON Invoices(MemberId);
GO

-- ============================================================
-- 9. Payments
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Payments' AND xtype='U')
CREATE TABLE Payments (
    PaymentId       INT             IDENTITY(1,1) PRIMARY KEY,
    InvoiceId       INT             NOT NULL REFERENCES Invoices(InvoiceId),
    Amount          DECIMAL(18,2)   NOT NULL,
    PaymentDate     DATETIME2       NOT NULL DEFAULT GETDATE(),
    PaymentMethod   NVARCHAR(30)    NOT NULL,                     
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Pending'    
                        CHECK (Status IN ('Pending','Completed','Failed','Refunded'))
);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Payments_InvoiceId' AND object_id = OBJECT_ID('Payments')) CREATE INDEX IX_Payments_InvoiceId ON Payments(InvoiceId);
GO

-- ============================================================
-- 10. Users (đăng nhập) - KHỚP ENTITY C# HIỆN TẠI
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
CREATE TABLE Users (
    UserId          INT             IDENTITY(1,1) PRIMARY KEY,
    Username        NVARCHAR(50)    NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(256)   NOT NULL,        -- BCrypt hash
    Role            NVARCHAR(20)    NOT NULL         -- SuperAdmin | Trainer | Member
                        CHECK (Role IN ('SuperAdmin','Trainer','Member')),
    MemberId        INT             NULL REFERENCES Members(MemberId),   -- nếu role=Member
    TrainerId       INT             NULL REFERENCES Trainers(TrainerId), -- nếu role=Trainer
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETDATE()
);
GO

-- Stored Procedures cho Users
CREATE OR ALTER PROCEDURE dbo.sp_User_GetByUsername
    @Username NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Username, PasswordHash, Role, MemberId, TrainerId, IsActive, CreatedAt
    FROM Users
    WHERE Username = @Username AND IsActive = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_User_GetById
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Username, PasswordHash, Role, MemberId, TrainerId, IsActive, CreatedAt
    FROM Users WHERE UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_User_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, Username, Role, MemberId, TrainerId, IsActive, CreatedAt
    FROM Users ORDER BY Role, Username;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_User_Create
    @Username     NVARCHAR(50),
    @PasswordHash NVARCHAR(256),
    @Role         NVARCHAR(20),
    @MemberId     INT = NULL,
    @TrainerId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Users (Username, PasswordHash, Role, MemberId, TrainerId)
    VALUES (@Username, @PasswordHash, @Role, @MemberId, @TrainerId);
    SELECT SCOPE_IDENTITY() AS UserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_User_UpdatePassword
    @UserId       INT,
    @PasswordHash NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users SET PasswordHash = @PasswordHash WHERE UserId = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_User_SetActive
    @UserId   INT,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users SET IsActive = @IsActive WHERE UserId = @UserId;
END;
GO

-- Trainer: xem member mình phụ trách
CREATE OR ALTER PROCEDURE dbo.sp_Trainer_GetMyMembers
    @TrainerId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DISTINCT m.MemberId, m.FullName, m.Phone, m.Email, m.Status, m.QRCodeValue
    FROM Members m
    INNER JOIN Schedules s ON s.MemberId = m.MemberId
    WHERE s.TrainerId = @TrainerId
    ORDER BY m.FullName;
END;
GO

PRINT 'Schema created successfully.';
GO
