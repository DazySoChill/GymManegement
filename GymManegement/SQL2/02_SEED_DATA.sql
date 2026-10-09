-- ============================================================
-- FILE: 02_SEED_DATA.sql
-- MÔ TẢ: Seed data ≥ 2000 records
-- Password mặc định: "gym@2026"
-- ============================================================

USE GymDb;
GO

SET NOCOUNT ON;

PRINT 'Starting seed data...';
PRINT 'Clearing existing data...';

-- Clear existing data (in correct order due to FK constraints)
DELETE FROM Checkins;
DELETE FROM Sessions;
DELETE FROM Payments;
DELETE FROM Invoices;
DELETE FROM Schedules;
DELETE FROM Memberships;
DELETE FROM Facilities;
DELETE FROM Users;
DELETE FROM Trainers;
DELETE FROM Members;

-- Reset identity seeds
DBCC CHECKIDENT ('Members', RESEED, 0);
DBCC CHECKIDENT ('Trainers', RESEED, 0);
DBCC CHECKIDENT ('Users', RESEED, 0);
DBCC CHECKIDENT ('Facilities', RESEED, 0);
DBCC CHECKIDENT ('Memberships', RESEED, 0);
DBCC CHECKIDENT ('Schedules', RESEED, 0);
DBCC CHECKIDENT ('Sessions', RESEED, 0);
DBCC CHECKIDENT ('Checkins', RESEED, 0);
DBCC CHECKIDENT ('Invoices', RESEED, 0);
DBCC CHECKIDENT ('Payments', RESEED, 0);

PRINT '✓ Cleared existing data';
GO

-- ============================================================
-- 1. USERS (Admin user)
-- ============================================================
DECLARE @PasswordHash NVARCHAR(256) = '$2a$11$k9d.p7zUiJ5Q7q.6SeUGV..V1AMPRQ0qCYvD9Go5SKZXQqq3EwhxS';

INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive) VALUES
('admin', @PasswordHash, N'Admin Gym', 'admin@gym.com', 'Admin', 1);

PRINT '✓ Seeded 1 Admin user';
GO

-- ============================================================
-- 2. TRAINERS (20 trainers)
-- ============================================================
SET IDENTITY_INSERT Trainers ON;

INSERT INTO Trainers (TrainerId, FullName, Phone, Email, Specialization) VALUES
(1, N'Đặng Văn Dũng',  '0987654321', 'dung.pt@gym.com', N'Bodybuilding & Fitness'),
(2, N'Vũ Thị Hoa',     '0976543210', 'hoa.pt@gym.com',  N'Yoga & Pilates'),
(3, N'Hoàng Đình Kiên','0965432109', 'kien.pt@gym.com', N'Boxing & Cardio'),
(4, N'Ngô Thanh Lam',  '0954321098', 'lam.pt@gym.com',  N'CrossFit'),
(5, N'Đỗ Mỹ Linh',     '0943210987', 'linh.pt@gym.com', N'Zumba & Dance'),
(6, N'Bùi Quốc Tuấn',  '0932109876', 'tuan.pt@gym.com', N'Powerlifting'),
(7, N'Lý Thị Mai',     '0921098765', 'mai.pt@gym.com',  N'Pilates & Rehab'),
(8, N'Phan Văn Nam',   '0910987654', 'nam.pt@gym.com',  N'Swimming'),
(9, N'Trịnh Thị Oanh', '0909876543', 'oanh.pt@gym.com', N'Cycling & Spin'),
(10, N'Võ Minh Phúc',  '0898765432', 'phuc.pt@gym.com', N'Martial Arts'),
(11, N'Đinh Văn Quang', '0887654321', 'quang.pt@gym.com', N'Bodybuilding'),
(12, N'Nguyễn Thị Hồng', '0876543210', 'hong.pt@gym.com', N'Yoga'),
(13, N'Trần Văn Khải', '0865432109', 'khai.pt@gym.com', N'Functional Training'),
(14, N'Lê Thị Lan',    '0854321098', 'lan.pt@gym.com',  N'Stretching'),
(15, N'Hoàng Minh Nam', '0843210987', 'nam2.pt@gym.com', N'Cardio'),
(16, N'Phạm Thị Quỳnh','0832109876', 'quynh.pt@gym.com', N'Pilates'),
(17, N'Ngô Văn Sơn',   '0821098765', 'son.pt@gym.com',  N'Boxing'),
(18, N'Đỗ Minh Tuấn',  '0810987654', 'tuan2.pt@gym.com', N'Strength & Conditioning'),
(19, N'Vũ Thị Vân',    '0809876543', 'van.pt@gym.com',  N'Aerial Yoga'),
(20, N'Bùi Văn Hùng',  '0798765432', 'hung.pt@gym.com', N'Calisthenics');

SET IDENTITY_INSERT Trainers OFF;

PRINT '✓ Seeded 20 Trainers';
GO

-- Tạo Users cho Trainers
DECLARE @PasswordHash NVARCHAR(256) = '$2a$11$k9d.p7zUiJ5Q7q.6SeUGV..V1AMPRQ0qCYvD9Go5SKZXQqq3EwhxS';

INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive)
SELECT 
    'trainer' + CAST(TrainerId AS NVARCHAR(10)),
    @PasswordHash,
    FullName,
    Email,
    'Trainer',
    1
FROM Trainers
WHERE TrainerId <= 20;

PRINT '✓ Seeded 20 Trainer users';
GO

-- ============================================================
-- 3. MEMBERS (2000 members)
-- ============================================================
SET IDENTITY_INSERT Members ON;

-- 10 members mẫu trước
INSERT INTO Members (MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue) VALUES
(1,  N'Nguyễn Văn An',   '0901234567', 'an.nguyen@gmail.com',   '1995-05-15', '2026-01-10', 'Active',   'MEMBER-00001-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(2,  N'Trần Thị Bích',   '0912345678', 'bich.tran@gmail.com',   '1998-08-20', '2026-02-01', 'Active',   'MEMBER-00002-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(3,  N'Lê Hoàng Cường',  '0923456789', 'cuong.le@gmail.com',    '1992-11-30', '2026-03-15', 'Active',   'MEMBER-00003-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(4,  N'Phạm Minh Đức',   '0934567890', 'duc.pham@gmail.com',    '2000-02-14', '2026-01-05', 'Active',   'MEMBER-00004-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(5,  N'Võ Thị Hằng',     '0945678901', 'hang.vo@gmail.com',     '1997-06-22', '2026-01-20', 'Active',   'MEMBER-00005-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(6,  N'Đinh Văn Khoa',   '0956789012', 'khoa.dinh@gmail.com',   '1993-09-10', '2026-02-15', 'Active',   'MEMBER-00006-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(7,  N'Hoàng Thị Linh',  '0967890123', 'linh.hoang@gmail.com',  '1999-03-05', '2026-03-01', 'Active',   'MEMBER-00007-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(8,  N'Ngô Minh Tuấn',   '0978901234', 'tuan.ngo@gmail.com',    '1994-12-18', '2026-01-25', 'Active',   'MEMBER-00008-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(9,  N'Trịnh Thị Oanh',  '0989012345', 'oanh.trinh@gmail.com',  '1996-07-08', '2026-02-20', 'Active',   'MEMBER-00009-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)),
(10, N'Lý Văn Phúc',     '0990123456', 'phuc.ly@gmail.com',     '1991-04-25', '2026-03-10', 'Inactive', 'MEMBER-00010-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8));

-- Generate 1990 more members (total 2000)
;WITH Numbers AS (
    SELECT 11 AS N
    UNION ALL
    SELECT N + 1 FROM Numbers WHERE N < 2000
)
INSERT INTO Members (MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue)
SELECT 
    N,
    N'Hội Viên ' + CAST(N AS NVARCHAR(10)),
    '09' + RIGHT('000000000' + CAST(N * 123456 AS NVARCHAR), 9),
    'member' + CAST(N AS NVARCHAR(10)) + '@gym.com',
    DATEADD(YEAR, -(20 + (N % 40)), CAST(GETDATE() AS DATE)),
    DATEADD(DAY, -(N % 365), CAST(GETDATE() AS DATE)),
    CASE WHEN N % 10 = 0 THEN 'Inactive' ELSE 'Active' END,
    'MEMBER-' + RIGHT('00000' + CAST(N AS NVARCHAR), 5) + '-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8)
FROM Numbers
OPTION (MAXRECURSION 2000);

SET IDENTITY_INSERT Members OFF;

PRINT '✓ Seeded 2000 Members';
GO

-- Tạo Users cho 10 members đầu
DECLARE @PasswordHash NVARCHAR(256) = '$2a$11$k9d.p7zUiJ5Q7q.6SeUGV..V1AMPRQ0qCYvD9Go5SKZXQqq3EwhxS';

INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive)
SELECT 
    'member' + CAST(MemberId AS NVARCHAR(10)),
    @PasswordHash,
    FullName,
    Email,
    'Member',
    1
FROM Members
WHERE MemberId <= 10;

PRINT '✓ Seeded 10 Member users (for first 10 members)';
GO

-- ============================================================
-- 4. FACILITIES (30 facilities)
-- ============================================================
INSERT INTO Facilities (FacilityName, FacilityType, Capacity, Status, Description) VALUES
-- Rooms
(N'Phòng Yoga 1', 'Room', 20, 'Available', N'Phòng tập Yoga với gương lớn'),
(N'Phòng Yoga 2', 'Room', 15, 'Available', N'Phòng Yoga nhỏ, yên tĩnh'),
(N'Phòng Boxing', 'Room', 10, 'Available', N'Phòng tập Boxing với bao cát'),
(N'Phòng Dance', 'Room', 25, 'Available', N'Phòng tập Dance rộng rãi'),
(N'Phòng Gym Chính', 'Room', 50, 'Available', N'Phòng gym chính với đầy đủ thiết bị'),
(N'Phòng Cardio', 'Room', 30, 'Available', N'Phòng máy chạy bộ và xe đạp'),
(N'Phòng Pilates', 'Room', 12, 'Available', N'Phòng Pilates với thảm tập'),
(N'Phòng Spinning', 'Room', 20, 'Available', N'Phòng xe đạp spinning'),
(N'Phòng CrossFit', 'Room', 15, 'Available', N'Phòng CrossFit với thiết bị chuyên dụng'),
(N'Phòng Stretching', 'Room', 10, 'Maintenance', N'Phòng giãn cơ (đang bảo trì)'),
-- Equipment
(N'Máy Chạy Bộ 1', 'Equipment', NULL, 'Available', N'Treadmill cao cấp'),
(N'Máy Chạy Bộ 2', 'Equipment', NULL, 'Available', N'Treadmill cao cấp'),
(N'Máy Chạy Bộ 3', 'Equipment', NULL, 'Available', N'Treadmill cao cấp'),
(N'Xe Đạp Tập 1', 'Equipment', NULL, 'Available', N'Stationary Bike'),
(N'Xe Đạp Tập 2', 'Equipment', NULL, 'Available', N'Stationary Bike'),
(N'Máy Đạp Đứng', 'Equipment', NULL, 'Available', N'Elliptical Machine'),
(N'Máy Đẩy Ngực', 'Equipment', NULL, 'Available', N'Chest Press Machine'),
(N'Máy Kéo Lưng', 'Equipment', NULL, 'Available', N'Lat Pulldown Machine'),
(N'Máy Đùi Trước', 'Equipment', NULL, 'Available', N'Leg Extension Machine'),
(N'Máy Đùi Sau', 'Equipment', NULL, 'Available', N'Leg Curl Machine'),
(N'Smith Machine', 'Equipment', NULL, 'Available', N'Smith Machine'),
(N'Squat Rack 1', 'Equipment', NULL, 'Available', N'Power Rack'),
(N'Squat Rack 2', 'Equipment', NULL, 'Available', N'Power Rack'),
(N'Bench Press', 'Equipment', NULL, 'Available', N'Bench Press Station'),
(N'Dumbbell Set', 'Equipment', NULL, 'Available', N'Bộ tạ đơn 2kg-50kg'),
(N'Barbell Set', 'Equipment', NULL, 'Available', N'Bộ tạ đòn'),
(N'Kettlebell Set', 'Equipment', NULL, 'Available', N'Bộ tạ Kettlebell'),
(N'Cable Machine', 'Equipment', NULL, 'Available', N'Máy cáp kéo đa năng'),
(N'Rowing Machine', 'Equipment', NULL, 'Maintenance', N'Máy chèo thuyền (bảo trì)'),
(N'Battle Ropes', 'Equipment', NULL, 'Available', N'Dây tập Battle Ropes');

PRINT '✓ Seeded 30 Facilities';
GO

-- ============================================================
-- 5. MEMBERSHIPS (500 memberships)
-- ============================================================
-- Tạo membership cho 500 members đầu
DECLARE @Counter INT = 1;
DECLARE @MemberId INT;
DECLARE @StartDate DATE;
DECLARE @EndDate DATE;
DECLARE @Type NVARCHAR(20);
DECLARE @Price DECIMAL(18,2);

WHILE @Counter <= 500
BEGIN
    SET @MemberId = @Counter;
    SET @StartDate = DATEADD(MONTH, -(@Counter % 6), CAST(GETDATE() AS DATE));
    
    -- Xác định type
    IF @Counter % 3 = 0
        SET @Type = 'Annual';
    ELSE IF @Counter % 3 = 1
        SET @Type = 'Quarterly';
    ELSE
        SET @Type = 'Monthly';
    
    -- Tính EndDate và Price
    IF @Type = 'Monthly'
    BEGIN
        SET @EndDate = DATEADD(MONTH, 1, @StartDate);
        SET @Price = 500000;
    END
    ELSE IF @Type = 'Quarterly'
    BEGIN
        SET @EndDate = DATEADD(MONTH, 3, @StartDate);
        SET @Price = 1200000;
    END
    ELSE
    BEGIN
        SET @EndDate = DATEADD(YEAR, 1, @StartDate);
        SET @Price = 4000000;
    END
    
    INSERT INTO Memberships (MemberId, MembershipType, Price, StartDate, EndDate, Status)
    VALUES (@MemberId, @Type, @Price, @StartDate, @EndDate, 
            CASE WHEN @EndDate < CAST(GETDATE() AS DATE) THEN 'Expired' ELSE 'Active' END);
    
    SET @Counter = @Counter + 1;
END;

PRINT '✓ Seeded 500 Memberships';
GO

-- ============================================================
-- 6. INVOICES (500 invoices - auto from memberships)
-- ============================================================
INSERT INTO Invoices (MemberId, MembershipId, Amount, IssueDate, DueDate, Status, Description)
SELECT 
    MemberId,
    MembershipId,
    Price,
    StartDate,
    DATEADD(DAY, 7, StartDate),
    CASE 
        WHEN MembershipId % 10 = 0 THEN 'Pending'
        WHEN MembershipId % 10 = 1 THEN 'Overdue'
        ELSE 'Paid'
    END,
    N'Phí ' + MembershipType + ' membership'
FROM Memberships
WHERE MembershipId <= 500;

PRINT '✓ Seeded 500 Invoices';
GO

-- ============================================================
-- 7. PAYMENTS (450 payments - 90% invoices đã thanh toán)
-- ============================================================
INSERT INTO Payments (InvoiceId, Amount, PaymentDate, PaymentMethod, Notes)
SELECT 
    InvoiceId,
    Amount,
    DATEADD(DAY, (InvoiceId % 5), IssueDate),
    CASE 
        WHEN InvoiceId % 3 = 0 THEN 'Cash'
        WHEN InvoiceId % 3 = 1 THEN 'Card'
        ELSE 'Transfer'
    END,
    N'Thanh toán ' + CASE 
        WHEN InvoiceId % 3 = 0 THEN 'tiền mặt'
        WHEN InvoiceId % 3 = 1 THEN 'thẻ'
        ELSE 'chuyển khoản'
    END
FROM Invoices
WHERE Status = 'Paid';

PRINT '✓ Seeded ~450 Payments';
GO

-- ============================================================
-- 8. SCHEDULES (200 schedules)
-- ============================================================
DECLARE @ScheduleCounter INT = 1;
WHILE @ScheduleCounter <= 200
BEGIN
    INSERT INTO Schedules (MemberId, TrainerId, FacilityId, ScheduledDate, StartTime, EndTime, Status, Notes)
    VALUES (
        (@ScheduleCounter % 100) + 1,
        (@ScheduleCounter % 20) + 1,
        (@ScheduleCounter % 10) + 1,
        DATEADD(DAY, @ScheduleCounter % 30, CAST(GETDATE() AS DATE)),
        DATEADD(HOUR, 8 + (@ScheduleCounter % 10), CAST('00:00' AS TIME)),
        DATEADD(HOUR, 9 + (@ScheduleCounter % 10), CAST('00:00' AS TIME)),
        CASE WHEN @ScheduleCounter % 5 = 0 THEN 'Completed' ELSE 'Scheduled' END,
        N'Lịch tập ' + CAST(@ScheduleCounter AS NVARCHAR)
    );
    SET @ScheduleCounter = @ScheduleCounter + 1;
END;

PRINT '✓ Seeded 200 Schedules';
GO

-- ============================================================
-- 9. SESSIONS (150 sessions)
-- ============================================================
INSERT INTO Sessions (ScheduleId, ActualStartTime, ActualEndTime, Notes)
SELECT 
    ScheduleId,
    StartTime,
    EndTime,
    N'Buổi tập hoàn thành'
FROM Schedules
WHERE Status = 'Completed';

PRINT '✓ Seeded ~150 Sessions';
GO

-- ============================================================
-- 10. CHECKINS (300 checkins)
-- ============================================================
DECLARE @CheckinCounter INT = 1;
WHILE @CheckinCounter <= 300
BEGIN
    INSERT INTO Checkins (MemberId, SessionId, CheckinTime, CheckinMethod)
    VALUES (
        (@CheckinCounter % 100) + 1,
        CASE WHEN (@CheckinCounter % 150) + 1 <= (SELECT COUNT(*) FROM Sessions) THEN (@CheckinCounter % 150) + 1 ELSE NULL END,
        DATEADD(HOUR, -(@CheckinCounter % 240), GETDATE()),
        CASE WHEN @CheckinCounter % 2 = 0 THEN 'QR' ELSE 'Manual' END
    );
    SET @CheckinCounter = @CheckinCounter + 1;
END;

PRINT '✓ Seeded 300 Checkins';
GO

-- ============================================================
-- SUMMARY
-- ============================================================
DECLARE @UserCount INT, @MemberCount INT, @TrainerCount INT, @FacilityCount INT;
DECLARE @MembershipCount INT, @InvoiceCount INT, @PaymentCount INT;
DECLARE @ScheduleCount INT, @SessionCount INT, @CheckinCount INT;

SELECT @UserCount = COUNT(*) FROM Users;
SELECT @MemberCount = COUNT(*) FROM Members;
SELECT @TrainerCount = COUNT(*) FROM Trainers;
SELECT @FacilityCount = COUNT(*) FROM Facilities;
SELECT @MembershipCount = COUNT(*) FROM Memberships;
SELECT @InvoiceCount = COUNT(*) FROM Invoices;
SELECT @PaymentCount = COUNT(*) FROM Payments;
SELECT @ScheduleCount = COUNT(*) FROM Schedules;
SELECT @SessionCount = COUNT(*) FROM Sessions;
SELECT @CheckinCount = COUNT(*) FROM Checkins;

PRINT '';
PRINT '========================================';
PRINT '✅ SEED DATA COMPLETE';
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '  Users:       ' + CAST(@UserCount AS NVARCHAR) + ' (1 Admin + 20 Trainers + 10 Members)';
PRINT '  Members:     ' + CAST(@MemberCount AS NVARCHAR);
PRINT '  Trainers:    ' + CAST(@TrainerCount AS NVARCHAR);
PRINT '  Facilities:  ' + CAST(@FacilityCount AS NVARCHAR);
PRINT '  Memberships: ' + CAST(@MembershipCount AS NVARCHAR);
PRINT '  Invoices:    ' + CAST(@InvoiceCount AS NVARCHAR);
PRINT '  Payments:    ' + CAST(@PaymentCount AS NVARCHAR);
PRINT '  Schedules:   ' + CAST(@ScheduleCount AS NVARCHAR);
PRINT '  Sessions:    ' + CAST(@SessionCount AS NVARCHAR);
PRINT '  Checkins:    ' + CAST(@CheckinCount AS NVARCHAR);
PRINT '';
PRINT 'Test accounts:';
PRINT '  admin / gym@2026        (Admin)';
PRINT '  trainer1 / gym@2026     (Trainer - Đặng Văn Dũng)';
PRINT '  member1 / gym@2026      (Member - Nguyễn Văn An)';
PRINT '';
PRINT 'Next: Run 03_STORED_PROCEDURES.sql (optional)';
GO
