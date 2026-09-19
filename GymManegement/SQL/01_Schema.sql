-- ============================================================
-- FILE: 01_Schema.sql
-- Mô tả: Tạo database GymDb và toàn bộ bảng
-- Chạy lần đầu để khởi tạo. Có thể chạy lại an toàn (IF NOT EXISTS).
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'GymDb')
    CREATE DATABASE GymDb;
GO

USE GymDb;
GO

-- ============================================================
-- 1. Members
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Members' AND xtype='U')
CREATE TABLE Members (
    MemberId        INT             IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Phone           NVARCHAR(20)    NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    DateOfBirth     DATE            NOT NULL,
    JoinDate        DATE            NOT NULL DEFAULT GETDATE(),
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Active'      -- Active | Inactive | Suspended
                        CHECK (Status IN ('Active','Inactive','Suspended')),
    QRCodeValue     NVARCHAR(50)    NOT NULL UNIQUE
);
GO

-- ============================================================
-- 2. Trainers
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
-- 3. Facilities
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

CREATE INDEX IX_Schedules_MemberId   ON Schedules(MemberId);
CREATE INDEX IX_Schedules_TrainerId  ON Schedules(TrainerId);
CREATE INDEX IX_Schedules_FacilityId ON Schedules(FacilityId);
GO

-- ============================================================
-- 6. Sessions (buổi tập thực tế)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Sessions' AND xtype='U')
CREATE TABLE Sessions (
    SessionId       INT             IDENTITY(1,1) PRIMARY KEY,
    ScheduleId      INT             NOT NULL REFERENCES Schedules(ScheduleId),
    SessionDate     DATE            NOT NULL,
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Scheduled'  -- Scheduled | Completed | Cancelled
                        CHECK (Status IN ('Scheduled','Completed','Cancelled'))
);
GO

CREATE INDEX IX_Sessions_ScheduleId ON Sessions(ScheduleId);
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

CREATE INDEX IX_Checkins_MemberId  ON Checkins(MemberId);
CREATE INDEX IX_Checkins_SessionId ON Checkins(SessionId);
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
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Pending'    -- Pending | Paid | Overdue | Cancelled
                        CHECK (Status IN ('Pending','Paid','Overdue','Cancelled'))
);
GO

CREATE INDEX IX_Invoices_MemberId ON Invoices(MemberId);
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
    PaymentMethod   NVARCHAR(30)    NOT NULL,                     -- Cash | BankTransfer | Card | MoMo | ZaloPay
    Status          NVARCHAR(30)    NOT NULL DEFAULT 'Pending'    -- Pending | Completed | Failed | Refunded
                        CHECK (Status IN ('Pending','Completed','Failed','Refunded'))
);
GO

CREATE INDEX IX_Payments_InvoiceId ON Payments(InvoiceId);
GO

PRINT 'Schema created successfully.';
