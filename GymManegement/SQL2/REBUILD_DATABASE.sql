-- ================================================================
-- REBUILD DATABASE - RUN THIS SCRIPT ONCE TO RESET EVERYTHING
-- File: REBUILD_DATABASE.sql
-- Description: Drop old database, create new schema, seed data
-- ================================================================

USE master;
GO

-- ================================================================
-- STEP 1: DROP OLD DATABASE IF EXISTS
-- ================================================================
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'GymDb')
BEGIN
    ALTER DATABASE GymDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GymDb;
    PRINT '✓ Old database GymDb dropped successfully';
END
ELSE
BEGIN
    PRINT '✓ No existing GymDb found (fresh install)';
END
GO

-- ================================================================
-- STEP 2: CREATE NEW DATABASE
-- ================================================================
CREATE DATABASE GymDb;
GO

PRINT '✓ New database GymDb created successfully';
GO

USE GymDb;
GO

-- ================================================================
-- STEP 3: CREATE SCHEMA (10 TABLES)
-- ================================================================

-- Table 1: Users
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Role NVARCHAR(50) NOT NULL CHECK (Role IN ('Admin', 'Trainer', 'Member')),
    IsActive BIT NOT NULL DEFAULT 1,
    LastLoginAt DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 2: Members
CREATE TABLE Members (
    MemberId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NULL,
    DateOfBirth DATE NULL,
    QRCode NVARCHAR(50) NOT NULL UNIQUE,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 3: Trainers
CREATE TABLE Trainers (
    TrainerId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NULL,
    Specialization NVARCHAR(200) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 4: Facilities
CREATE TABLE Facilities (
    FacilityId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Available' CHECK (Status IN ('Available', 'Maintenance', 'OutOfService')),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 5: Memberships
CREATE TABLE Memberships (
    MembershipId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    PackageName NVARCHAR(200) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 6: Schedules
CREATE TABLE Schedules (
    ScheduleId INT IDENTITY(1,1) PRIMARY KEY,
    TrainerId INT NOT NULL FOREIGN KEY REFERENCES Trainers(TrainerId),
    FacilityId INT NOT NULL FOREIGN KEY REFERENCES Facilities(FacilityId),
    ClassName NVARCHAR(200) NOT NULL,
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NOT NULL,
    MaxCapacity INT NOT NULL DEFAULT 20,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 7: Sessions
CREATE TABLE Sessions (
    SessionId INT IDENTITY(1,1) PRIMARY KEY,
    ScheduleId INT NOT NULL FOREIGN KEY REFERENCES Schedules(ScheduleId),
    MemberId INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    RegistrationDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(50) NOT NULL DEFAULT 'Registered' CHECK (Status IN ('Registered', 'Attended', 'Cancelled')),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 8: Checkins
CREATE TABLE Checkins (
    CheckinId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    CheckinTime DATETIME NOT NULL DEFAULT GETDATE(),
    CheckoutTime DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 9: Invoices
CREATE TABLE Invoices (
    InvoiceId INT IDENTITY(1,1) PRIMARY KEY,
    MembershipId INT NOT NULL FOREIGN KEY REFERENCES Memberships(MembershipId),
    InvoiceDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Paid', 'PartiallyPaid', 'Overdue', 'Cancelled')),
    Description NVARCHAR(MAX) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

-- Table 10: Payments
CREATE TABLE Payments (
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceId INT NOT NULL FOREIGN KEY REFERENCES Invoices(InvoiceId),
    Amount DECIMAL(18,2) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL CHECK (PaymentMethod IN ('Cash', 'Card', 'BankTransfer', 'Momo', 'ZaloPay')),
    PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);

PRINT '✓ Schema created: 10 tables with constraints';
GO

-- ================================================================
-- STEP 4: SEED DATA
-- ================================================================

-- Clear existing data (if any)
DELETE FROM Payments;
DELETE FROM Invoices;
DELETE FROM Checkins;
DELETE FROM Sessions;
DELETE FROM Schedules;
DELETE FROM Memberships;
DELETE FROM Facilities;
DELETE FROM Trainers;
DELETE FROM Members;
DELETE FROM Users;

-- Reset identity seeds
DBCC CHECKIDENT ('Payments', RESEED, 0);
DBCC CHECKIDENT ('Invoices', RESEED, 0);
DBCC CHECKIDENT ('Checkins', RESEED, 0);
DBCC CHECKIDENT ('Sessions', RESEED, 0);
DBCC CHECKIDENT ('Schedules', RESEED, 0);
DBCC CHECKIDENT ('Memberships', RESEED, 0);
DBCC CHECKIDENT ('Facilities', RESEED, 0);
DBCC CHECKIDENT ('Trainers', RESEED, 0);
DBCC CHECKIDENT ('Members', RESEED, 0);
DBCC CHECKIDENT ('Users', RESEED, 0);

PRINT '✓ Existing data cleared, identity seeds reset';

-- Insert Users (Admin, Trainers, Members)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, LastLoginAt)
VALUES 
-- Admin (password: gym@2026)
('admin', '$2a$11$Xg1J5tZzQKZN3qH4v9F0.e7XGJZYvK5mXzLQzN4jH9fK5mX0zN4jH', 'System Admin', 'admin@gym.com', 'Admin', 1, NULL),

-- Trainers (password: gym@2026)
('trainer1', '$2a$11$Xg1J5tZzQKZN3qH4v9F0.e7XGJZYvK5mXzLQzN4jH9fK5mX0zN4jH', 'Nguyễn Văn Trainer 1', 'trainer1@gym.com', 'Trainer', 1, NULL),
('trainer2', '$2a$11$Xg1J5tZzQKZN3qH4v9F0.e7XGJZYvK5mXzLQzN4jH9fK5mX0zN4jH', 'Trần Thị Trainer 2', 'trainer2@gym.com', 'Trainer', 1, NULL),
('trainer3', '$2a$11$Xg1J5tZzQKZN3qH4v9F0.e7XGJZYvK5mXzLQzN4jH9fK5mX0zN4jH', 'Lê Văn Trainer 3', 'trainer3@gym.com', 'Trainer', 1, NULL),
('trainer4', '$2a$11$Xg1J5tZzQKZN3qH4v9F0.e7XGJZYvK5mXzLQzN4jH9fK5mX0zN4jH', 'Phạm Thị Trainer 4', 'trainer4@gym.com', 'Trainer', 1, NULL),
('trainer5', '$2a$11$Xg1J5tZzQKZN3qH4v9F0.e7XGJZYvK5mXzLQzN4jH9fK5mX0zN4jH', 'Hoàng Văn Trainer 5', 'trainer5@gym.com', 'Trainer', 1, NULL);

-- Members (password: gym@2026) - 500 members
DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive)
    VALUES 
    (
        'member' + CAST(@i AS NVARCHAR(10)),
        '$2a$11$Xg1J5tZzQKZN3qH4v9F0.e7XGJZYvK5mXzLQzN4jH9fK5mX0zN4jH',
        N'Member ' + CAST(@i AS NVARCHAR(10)),
        'member' + CAST(@i AS NVARCHAR(10)) + '@example.com',
        'Member',
        1
    );
    SET @i = @i + 1;
END;

PRINT '✓ Inserted 506 users (1 Admin, 5 Trainers, 500 Members)';

-- Insert Trainers
INSERT INTO Trainers (FullName, Email, Phone, Specialization)
VALUES 
('Nguyễn Văn Trainer 1', 'trainer1@gym.com', '0901234567', 'Yoga & Pilates'),
('Trần Thị Trainer 2', 'trainer2@gym.com', '0901234568', 'Boxing & Martial Arts'),
('Lê Văn Trainer 3', 'trainer3@gym.com', '0901234569', 'Weight Training'),
('Phạm Thị Trainer 4', 'trainer4@gym.com', '0901234570', 'Cardio & HIIT'),
('Hoàng Văn Trainer 5', 'trainer5@gym.com', '0901234571', 'Swimming & Aqua Fitness');

PRINT '✓ Inserted 5 trainers';

-- Insert Members (500 members)
DECLARE @j INT = 1;
WHILE @j <= 500
BEGIN
    INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode)
    VALUES 
    (
        N'Member ' + CAST(@j AS NVARCHAR(10)),
        'member' + CAST(@j AS NVARCHAR(10)) + '@example.com',
        '090' + RIGHT('0000000' + CAST(@j AS NVARCHAR(7)), 7),
        DATEADD(YEAR, -(@j % 40 + 18), GETDATE()),
        'M' + RIGHT('000000' + CAST(@j AS NVARCHAR(6)), 6)
    );
    SET @j = @j + 1;
END;

PRINT '✓ Inserted 500 members with QR codes';

-- Insert Facilities
INSERT INTO Facilities (Name, Description, Status)
VALUES 
(N'Phòng tập Yoga 1', N'Phòng tập Yoga với đầy đủ trang thiết bị', 'Available'),
(N'Phòng tập Boxing', N'Phòng tập Boxing chuyên nghiệp', 'Available'),
(N'Khu vực tạ', N'Khu vực tạ với máy móc hiện đại', 'Available'),
(N'Bể bơi trong nhà', N'Bể bơi tiêu chuẩn Olympic', 'Available'),
(N'Phòng Cardio', N'Phòng tập Cardio với máy chạy bộ, xe đạp', 'Available'),
(N'Sân tennis', N'Sân tennis ngoài trời', 'Maintenance'),
(N'Phòng Spinning', N'Phòng tập Spinning', 'Available'),
(N'Khu vực Crossfit', N'Khu vực tập Crossfit', 'Available'),
(N'Phòng tập Dance', N'Phòng tập nhảy hiện đại', 'Available'),
(N'Sauna & Steam Room', N'Phòng xông hơi', 'Available');

PRINT '✓ Inserted 10 facilities';

-- Insert Memberships (500 memberships)
DECLARE @k INT = 1;
DECLARE @packages TABLE (PackageName NVARCHAR(200), Price DECIMAL(18,2));
INSERT INTO @packages VALUES 
(N'Gói 1 tháng', 500000),
(N'Gói 3 tháng', 1400000),
(N'Gói 6 tháng', 2600000),
(N'Gói 12 tháng', 4800000);

WHILE @k <= 500
BEGIN
    DECLARE @pkg NVARCHAR(200);
    DECLARE @price DECIMAL(18,2);
    DECLARE @months INT;
    
    SELECT TOP 1 @pkg = PackageName, @price = Price FROM @packages ORDER BY NEWID();
    SET @months = CASE 
        WHEN @pkg LIKE N'%1 tháng%' THEN 1
        WHEN @pkg LIKE N'%3 tháng%' THEN 3
        WHEN @pkg LIKE N'%6 tháng%' THEN 6
        ELSE 12
    END;
    
    INSERT INTO Memberships (MemberId, PackageName, Price, StartDate, EndDate)
    VALUES 
    (
        @k,
        @pkg,
        @price,
        DATEADD(DAY, -(@k % 180), GETDATE()),
        DATEADD(MONTH, @months, DATEADD(DAY, -(@k % 180), GETDATE()))
    );
    SET @k = @k + 1;
END;

PRINT '✓ Inserted 500 memberships';

-- Insert Schedules (100 schedules)
DECLARE @m INT = 1;
WHILE @m <= 100
BEGIN
    DECLARE @startTime DATETIME = DATEADD(HOUR, (@m % 12) + 6, DATEADD(DAY, @m % 30, GETDATE()));
    INSERT INTO Schedules (TrainerId, FacilityId, ClassName, StartTime, EndTime, MaxCapacity)
    VALUES 
    (
        ((@m - 1) % 5) + 1,
        ((@m - 1) % 10) + 1,
        N'Class ' + CAST(@m AS NVARCHAR(10)),
        @startTime,
        DATEADD(HOUR, 1, @startTime),
        20
    );
    SET @m = @m + 1;
END;

PRINT '✓ Inserted 100 schedules';

-- Insert Sessions (300 sessions)
DECLARE @n INT = 1;
WHILE @n <= 300
BEGIN
    INSERT INTO Sessions (ScheduleId, MemberId, RegistrationDate, Status)
    VALUES 
    (
        ((@n - 1) % 100) + 1,
        ((@n - 1) % 500) + 1,
        DATEADD(DAY, -(@n % 60), GETDATE()),
        CASE (@n % 3) WHEN 0 THEN 'Attended' WHEN 1 THEN 'Registered' ELSE 'Cancelled' END
    );
    SET @n = @n + 1;
END;

PRINT '✓ Inserted 300 sessions';

-- Insert Checkins (200 checkins)
DECLARE @p INT = 1;
WHILE @p <= 200
BEGIN
    DECLARE @checkinTime DATETIME = DATEADD(HOUR, -(@p % 240), GETDATE());
    INSERT INTO Checkins (MemberId, CheckinTime, CheckoutTime)
    VALUES 
    (
        ((@p - 1) % 500) + 1,
        @checkinTime,
        CASE WHEN @p % 3 = 0 THEN DATEADD(HOUR, 2, @checkinTime) ELSE NULL END
    );
    SET @p = @p + 1;
END;

PRINT '✓ Inserted 200 checkins';

-- Insert Invoices (500 invoices - one per membership)
DECLARE @q INT = 1;
WHILE @q <= 500
BEGIN
    DECLARE @msPrice DECIMAL(18,2);
    DECLARE @msEndDate DATE;
    SELECT @msPrice = Price, @msEndDate = EndDate FROM Memberships WHERE MembershipId = @q;
    
    INSERT INTO Invoices (MembershipId, InvoiceDate, DueDate, TotalAmount, Status, Description)
    VALUES 
    (
        @q,
        GETDATE(),
        @msEndDate,
        @msPrice,
        CASE (@q % 4) WHEN 0 THEN 'Paid' WHEN 1 THEN 'Pending' WHEN 2 THEN 'PartiallyPaid' ELSE 'Paid' END,
        N'Hóa đơn cho gói tập Membership ' + CAST(@q AS NVARCHAR(10))
    );
    SET @q = @q + 1;
END;

PRINT '✓ Inserted 500 invoices';

-- Insert Payments (400 payments)
DECLARE @r INT = 1;
WHILE @r <= 400
BEGIN
    DECLARE @invoiceId INT = ((@r - 1) % 500) + 1;
    DECLARE @invoiceAmount DECIMAL(18,2);
    SELECT @invoiceAmount = TotalAmount FROM Invoices WHERE InvoiceId = @invoiceId;
    
    INSERT INTO Payments (InvoiceId, Amount, PaymentMethod, PaymentDate)
    VALUES 
    (
        @invoiceId,
        @invoiceAmount * (CASE (@r % 3) WHEN 0 THEN 1.0 WHEN 1 THEN 0.5 ELSE 1.0 END),
        CASE (@r % 5) WHEN 0 THEN 'Cash' WHEN 1 THEN 'Card' WHEN 2 THEN 'BankTransfer' WHEN 3 THEN 'Momo' ELSE 'ZaloPay' END,
        DATEADD(DAY, -(@r % 90), GETDATE())
    );
    SET @r = @r + 1;
END;

PRINT '✓ Inserted 400 payments';
GO

-- ================================================================
-- STEP 5: VERIFICATION
-- ================================================================
PRINT '';
PRINT '========================================';
PRINT 'DATABASE REBUILD COMPLETED SUCCESSFULLY';
PRINT '========================================';
PRINT '';
PRINT 'Record counts:';

SELECT 'Users' AS TableName, COUNT(*) AS RecordCount FROM Users
UNION ALL
SELECT 'Members', COUNT(*) FROM Members
UNION ALL
SELECT 'Trainers', COUNT(*) FROM Trainers
UNION ALL
SELECT 'Facilities', COUNT(*) FROM Facilities
UNION ALL
SELECT 'Memberships', COUNT(*) FROM Memberships
UNION ALL
SELECT 'Schedules', COUNT(*) FROM Schedules
UNION ALL
SELECT 'Sessions', COUNT(*) FROM Sessions
UNION ALL
SELECT 'Checkins', COUNT(*) FROM Checkins
UNION ALL
SELECT 'Invoices', COUNT(*) FROM Invoices
UNION ALL
SELECT 'Payments', COUNT(*) FROM Payments;

PRINT '';
PRINT 'Test accounts:';
PRINT '  - admin/gym@2026 (Admin)';
PRINT '  - trainer1/gym@2026 (Trainer)';
PRINT '  - member1/gym@2026 (Member)';
PRINT '';
PRINT '✓ Ready to test API!';
GO
