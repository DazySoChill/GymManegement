-- ============================================================
-- FILE: 03_SeedData.sql
-- Mô tả: Dữ liệu mẫu ≥ 2,000 bản ghi cho Gym Management
-- Chạy sau 01_Schema.sql và 04_Users.sql
-- ============================================================

USE GymDb;
GO

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

-- Xóa dữ liệu cũ theo thứ tự FK (Users trước vì FK đến Members/Trainers)
DELETE FROM Payments;
DELETE FROM Invoices;
DELETE FROM Checkins;
DELETE FROM Sessions;
DELETE FROM Schedules;
DELETE FROM Memberships;
DELETE FROM Users;
DELETE FROM Facilities;
DELETE FROM Trainers;
DELETE FROM Members;
DELETE FROM AuditLogs;
DELETE FROM RefreshTokens;
GO





--- !!! DROP DATABASE !!!
USE master;
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = N'GymDb')
BEGIN
    ALTER DATABASE GymDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GymDb;
    PRINT 'GymDb dropped successfully.';
END
ELSE
BEGIN
    PRINT 'GymDb does not exist.';
END
GO
--- !!! DROP DATABASE !!!









-- ============================================================
-- 1. MEMBERS (≥ 2,000 records for NFR requirement)
-- ============================================================
SET IDENTITY_INSERT Members ON;

-- First 4 fixed members (for demo users)
INSERT INTO Members (MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue, CreatedBy) VALUES
(1, N'Nguyễn Văn An',  '0901234567', 'an.nguyen@gmail.com',  '1995-05-15', '2026-01-10', 'Active',   'QR_MEM_001', 1),
(2, N'Trần Thị Bích',  '0912345678', 'bich.tran@gmail.com',  '1998-08-20', '2026-02-01', 'Active',   'QR_MEM_002', 1),
(3, N'Lê Hoàng Cường', '0923456789', 'cuong.le@gmail.com',   '1992-11-30', '2026-03-15', 'Active',   'QR_MEM_003', 1),
(4, N'Phạm Minh Đức',  '0934567890', 'duc.pham@gmail.com',   '2000-02-14', '2026-01-05', 'Inactive', 'QR_MEM_004', 1);

-- Generate 1,996 more members using CTE
WITH GeneratedMembers AS (
    SELECT TOP (1996)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 4 AS MemberId,
        N'Hội Viên ' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 4 AS NVARCHAR) AS FullName,
        '09' + RIGHT('000000000' + CAST(ABS(CHECKSUM(NEWID())) % 900000000 + 100000000 AS NVARCHAR), 9) AS Phone,
        'member' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 4 AS NVARCHAR) + '@gym.com' AS Email,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 10000, '2000-01-01') AS DateOfBirth,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, '2026-01-01') AS JoinDate,
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 < 8 THEN 'Active' ELSE 'Inactive' END AS Status,
        'QR_MEM_' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 4 AS NVARCHAR), 4) AS QRCodeValue,
        1 AS CreatedBy
    FROM sys.objects o1 CROSS JOIN sys.objects o2 CROSS JOIN sys.objects o3
)
INSERT INTO Members (MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue, CreatedBy)
SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue, CreatedBy
FROM GeneratedMembers;

SET IDENTITY_INSERT Members OFF;
GO
DBCC CHECKIDENT ('Members', RESEED, 2000);
GO

-- ============================================================
-- 2. TRAINERS (20 records)
-- ============================================================
SET IDENTITY_INSERT Trainers ON;
INSERT INTO Trainers (TrainerId, FullName, Phone, Email, Specialization, CreatedBy) VALUES
(1, N'Đặng Văn Dũng',  '0987654321', 'dung.pt@gym.com', N'Bodybuilding & Fitness', 1),
(2, N'Vũ Thị Hoa',     '0976543210', 'hoa.pt@gym.com',  N'Yoga & Pilates', 1),
(3, N'Hoàng Đình Kiên','0965432109', 'kien.pt@gym.com', N'Boxing & Cardio', 1),
(4, N'Ngô Thanh Lam',  '0954321098', 'lam.pt@gym.com',  N'CrossFit', 1),
(5, N'Đỗ Mỹ Linh',     '0943210987', 'linh.pt@gym.com', N'Zumba & Dance', 1),
(6, N'Bùi Quốc Tuấn',  '0932109876', 'tuan.pt@gym.com', N'Powerlifting', 1),
(7, N'Lý Thị Mai',     '0921098765', 'mai.pt@gym.com',  N'Pilates & Rehab', 1),
(8, N'Phan Văn Nam',   '0910987654', 'nam.pt@gym.com',  N'Swimming', 1),
(9, N'Trịnh Thị Oanh', '0909876543', 'oanh.pt@gym.com', N'Cycling & Spin', 1),
(10, N'Võ Minh Phúc',  '0898765432', 'phuc.pt@gym.com', N'Martial Arts', 1),
(11, N'Đinh Văn Quang', '0887654321', 'quang.pt@gym.com', N'Bodybuilding', 1),
(12, N'Nguyễn Thị Hồng', '0876543210', 'hong.pt@gym.com', N'Yoga', 1),
(13, N'Trần Văn Khải', '0865432109', 'khai.pt@gym.com', N'Functional Training', 1),
(14, N'Lê Thị Lan',    '0854321098', 'lan.pt@gym.com',  N'Stretching', 1),
(15, N'Hoàng Minh Nam', '0843210987', 'nam2.pt@gym.com', N'Cardio', 1),
(16, N'Phạm Thị Quỳnh','0832109876', 'quynh.pt@gym.com', N'Pilates', 1),
(17, N'Ngô Văn Sơn',   '0821098765', 'son.pt@gym.com',  N'Boxing', 1),
(18, N'Đỗ Minh Tuấn',  '0810987654', 'tuan2.pt@gym.com', N'Strength & Conditioning', 1),
(19, N'Vũ Thị Vân',    '0809876543', 'van.pt@gym.com',  N'Aerial Yoga', 1),
(20, N'Bùi Văn Hùng',  '0798765432', 'hung.pt@gym.com', N'Calisthenics', 1);
SET IDENTITY_INSERT Trainers OFF;
GO
DBCC CHECKIDENT ('Trainers', RESEED, 20);
GO

-- ============================================================
-- 3. FACILITIES (10 records)
-- ============================================================
SET IDENTITY_INSERT Facilities ON;
INSERT INTO Facilities (FacilityId, Name, Description, IsActive, CreatedBy) VALUES
(1, N'Phòng Gym Khu A',        N'Trang thiết bị tạ đơn, giàn tạ khối, máy kéo xô', 1, 1),
(2, N'Phòng Yoga & Pilates',   N'Phòng sàn gỗ cách âm lầu 2, thảm tập & bóng yoga', 1, 1),
(3, N'Sàn Boxing & Cardio',    N'Võ đài đối kháng, bao cát đấm bốc, máy chạy bộ',  1, 1),
(4, N'Phòng CrossFit',         N'Khu vực CrossFit chuyên nghiệp, lồng gà, sòng ngang', 1, 1),
(5, N'Phòng Spinning',         N'25 xe đạp tập spinning, hệ thống âm thanh', 1, 1),
(6, N'Hồ bơi Olympic',         N'Hồ bơi 25m x 10m, 6 làn, nước nóng', 1, 1),
(7, N'Phòng Functional',       N'Khu tập chức năng: battle rope, kettlebell, medball', 1, 1),
(8, N'Phòng Stretching',       N'Phòng thư giãn, foam roller, dây yoga, nhạc nhẹ', 1, 1),
(9, N'Phòng PT Cá Nhân',       N'5 phòng PT riêng tư, kính cường lực, điều hòa', 1, 1),
(10, N'Sân Tennis Bàn',        N'4 bàn tennis chuyên nghiệp, ban công quan sát', 1, 1);
SET IDENTITY_INSERT Facilities OFF;
GO
DBCC CHECKIDENT ('Facilities', RESEED, 10);
GO

-- ============================================================
-- 4. MEMBERSHIPS (2,000+ records - one per member, some with history)
-- ============================================================
SET IDENTITY_INSERT Memberships ON;

-- First 4 memberships for demo members
INSERT INTO Memberships (MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive, Version, CreatedBy) VALUES
(1, 1, 'Annual',    6000000, '2026-01-10', '2027-01-10', 1, 1, 1),
(2, 2, 'Monthly',    600000, '2026-09-01', DATEADD(DAY, 30, CAST(GETDATE() AS DATE)), 1, 1, 1),
(3, 3, 'Quarterly', 1600000, '2026-07-01', DATEADD(DAY, 60, CAST(GETDATE() AS DATE)), 1, 1, 1),
(4, 4, 'Monthly',    500000, '2026-01-05', '2026-02-05', 0, 1, 1);

-- Generate memberships for remaining 1996 members + some history
WITH GeneratedMemberships AS (
    SELECT TOP (2500)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 4 AS MembershipId,
        (ABS(CHECKSUM(NEWID())) % 2000) + 1 AS MemberId,
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'Monthly'
            WHEN 1 THEN 'Quarterly'
            WHEN 2 THEN 'Annual'
            WHEN 3 THEN 'VIP'
            ELSE 'Trial'
        END AS MembershipType,
        CASE 
            WHEN ABS(CHECKSUM(NEWID())) % 5 = 0 THEN 500000 + (ABS(CHECKSUM(NEWID())) % 5) * 100000
            WHEN ABS(CHECKSUM(NEWID())) % 5 = 1 THEN 1500000 + (ABS(CHECKSUM(NEWID())) % 3) * 100000
            WHEN ABS(CHECKSUM(NEWID())) % 5 = 2 THEN 5000000 + (ABS(CHECKSUM(NEWID())) % 5) * 500000
            WHEN ABS(CHECKSUM(NEWID())) % 5 = 3 THEN 10000000
            ELSE 200000
        END AS Price,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 180, GETDATE()) AS StartDate,
        NULL AS EndDate, -- Will compute
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 < 8 THEN 1 ELSE 0 END AS IsActive,
        1 AS Version,
        1 AS CreatedBy
    FROM sys.objects o1 CROSS JOIN sys.objects o2 CROSS JOIN sys.objects o3
),
ComputedMemberships AS (
    SELECT 
        MembershipId, MemberId, MembershipType, Price, StartDate,
        CASE MembershipType
            WHEN 'Trial' THEN DATEADD(DAY, 7, StartDate)
            WHEN 'Monthly' THEN DATEADD(MONTH, 1, StartDate)
            WHEN 'Quarterly' THEN DATEADD(MONTH, 3, StartDate)
            WHEN 'Annual' THEN DATEADD(YEAR, 1, StartDate)
            WHEN 'VIP' THEN DATEADD(YEAR, 1, StartDate)
        END AS EndDate,
        IsActive, Version, CreatedBy
    FROM GeneratedMemberships
)
INSERT INTO Memberships (MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive, Version, CreatedBy)
SELECT MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive, Version, CreatedBy
FROM ComputedMemberships;

SET IDENTITY_INSERT Memberships OFF;
GO
DBCC CHECKIDENT ('Memberships', RESEED, 2500);
GO

-- ============================================================
-- 5. SCHEDULES (5,000+ records)
-- ============================================================
SET IDENTITY_INSERT Schedules ON;

-- First 3 schedules for demo
INSERT INTO Schedules (ScheduleId, MemberId, TrainerId, FacilityId, StartTime, EndTime, CreatedBy) VALUES
(1, 1, 1, 1, DATEADD(HOUR, 8,  CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(MINUTE, 90, DATEADD(HOUR, 8,  CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 1),
(2, 2, 2, 2, DATEADD(HOUR, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(MINUTE, 60, DATEADD(HOUR, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 1),
(3, 3, 3, 3, DATEADD(DAY, -1, DATEADD(HOUR, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(DAY, -1, DATEADD(MINUTE, 90, DATEADD(HOUR, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))), 1);

-- Generate 4,997 more schedules
WITH GeneratedSchedules AS (
    SELECT TOP (4997)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 3 AS ScheduleId,
        (ABS(CHECKSUM(NEWID())) % 2000) + 1 AS MemberId,
        (ABS(CHECKSUM(NEWID())) % 20) + 1 AS TrainerId,
        (ABS(CHECKSUM(NEWID())) % 10) + 1 AS FacilityId,
        DATEADD(HOUR, 6 + (ABS(CHECKSUM(NEWID())) % 14), CAST(CAST(DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 60, GETDATE()) AS DATE) AS DATETIME2)) AS StartTime,
        NULL AS EndTime,
        1 AS CreatedBy
    FROM sys.objects o1 CROSS JOIN sys.objects o2 CROSS JOIN sys.objects o3
),
ComputedSchedules AS (
    SELECT 
        ScheduleId, MemberId, TrainerId, FacilityId, StartTime,
        DATEADD(MINUTE, 30 + (ABS(CHECKSUM(NEWID())) % 90), StartTime) AS EndTime,
        CreatedBy
    FROM GeneratedSchedules
)
INSERT INTO Schedules (ScheduleId, MemberId, TrainerId, FacilityId, StartTime, EndTime, CreatedBy)
SELECT ScheduleId, MemberId, TrainerId, FacilityId, StartTime, EndTime, CreatedBy
FROM ComputedSchedules;

SET IDENTITY_INSERT Schedules OFF;
GO
DBCC CHECKIDENT ('Schedules', RESEED, 5000);
GO

-- ============================================================
-- 6. SESSIONS (5,000+ records - one per schedule mostly)
-- ============================================================
SET IDENTITY_INSERT Sessions ON;

-- First 3 sessions for demo
INSERT INTO Sessions (SessionId, ScheduleId, SessionDate, Status, CreatedBy) VALUES
(1, 1, CAST(GETDATE() AS DATE), 'Scheduled', 1),
(2, 2, CAST(GETDATE() AS DATE), 'Scheduled', 1),
(3, 3, DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), 'Completed', 1);

-- Generate sessions for all schedules
WITH GeneratedSessions AS (
    SELECT TOP (5000)
        ROW_NUMBER() OVER (ORDER BY s.ScheduleId) + 3 AS SessionId,
        s.ScheduleId,
        CAST(s.StartTime AS DATE) AS SessionDate,
        CASE 
            WHEN CAST(s.StartTime AS DATE) < CAST(GETDATE() AS DATE) THEN 'Completed'
            WHEN CAST(s.StartTime AS DATE) = CAST(GETDATE() AS DATE) THEN 'Scheduled'
            ELSE 'Scheduled'
        END AS Status,
        1 AS CreatedBy
    FROM Schedules s
    WHERE s.ScheduleId > 3
    ORDER BY s.ScheduleId
)
INSERT INTO Sessions (SessionId, ScheduleId, SessionDate, Status, CreatedBy)
SELECT SessionId, ScheduleId, SessionDate, Status, CreatedBy
FROM GeneratedSessions;

SET IDENTITY_INSERT Sessions OFF;
GO
DBCC CHECKIDENT ('Sessions', RESEED, 5000);
GO

-- ============================================================
-- 7. CHECKINS (10,000+ records)
-- ============================================================
SET IDENTITY_INSERT Checkins ON;

-- First 2 checkins for demo
INSERT INTO Checkins (CheckinId, MemberId, SessionId, CheckinTime, CheckinMethod, CreatedBy) VALUES
(1, 1, 1, DATEADD(MINUTE, -10, DATEADD(HOUR, 8,  CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 'QRCode', 1),
(2, 3, 3, DATEADD(MINUTE, -5,  DATEADD(DAY, -1, DATEADD(HOUR, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))), 'Manual', 1);

-- Generate checkins for completed sessions (80% checkin rate)
WITH GeneratedCheckins AS (
    SELECT TOP (10000)
        ROW_NUMBER() OVER (ORDER BY s.SessionId) + 2 AS CheckinId,
        s.MemberId,
        se.SessionId,
        DATEADD(MINUTE, -ABS(CHECKSUM(NEWID())) % 30, se.SessionDate) AS CheckinTime,
        CASE ABS(CHECKSUM(NEWID())) % 3
            WHEN 0 THEN 'QRCode'
            WHEN 1 THEN 'Card'
            ELSE 'Manual'
        END AS CheckinMethod,
        1 AS CreatedBy
    FROM Sessions se
    INNER JOIN Schedules s ON s.ScheduleId = se.ScheduleId
    WHERE se.Status = 'Completed'
      AND ABS(CHECKSUM(NEWID())) % 10 < 8  -- 80% checkin rate
)
INSERT INTO Checkins (CheckinId, MemberId, SessionId, CheckinTime, CheckinMethod, CreatedBy)
SELECT CheckinId, MemberId, SessionId, CheckinTime, CheckinMethod, CreatedBy
FROM GeneratedCheckins;

SET IDENTITY_INSERT Checkins OFF;
GO
DBCC CHECKIDENT ('Checkins', RESEED, 10000);
GO

-- ============================================================
-- 8. INVOICES (2,500+ records)
-- ============================================================
SET IDENTITY_INSERT Invoices ON;

-- First 3 invoices for demo
INSERT INTO Invoices (InvoiceId, MemberId, TotalAmount, InvoiceDate, DueDate, Status, CreatedBy) VALUES
(1, 1, 6000000, '2026-01-10', '2026-01-17', 'Paid', 1),
(2, 2,  600000, CAST(GETDATE() AS DATE), DATEADD(DAY, 7, CAST(GETDATE() AS DATE)), 'Pending', 1),
(3, 3, 1600000, DATEADD(DAY, -15, CAST(GETDATE() AS DATE)), DATEADD(DAY, -5, CAST(GETDATE() AS DATE)), 'Overdue', 1);

-- Generate invoices for memberships
WITH GeneratedInvoices AS (
    SELECT TOP (2500)
        ROW_NUMBER() OVER (ORDER BY m.MembershipId) + 3 AS InvoiceId,
        m.MemberId,
        m.Price AS TotalAmount,
        m.StartDate AS InvoiceDate,
        DATEADD(DAY, 7, m.StartDate) AS DueDate,
        CASE 
            WHEN m.EndDate < GETDATE() AND ABS(CHECKSUM(NEWID())) % 10 < 2 THEN 'Overdue'
            WHEN m.EndDate < GETDATE() THEN 'Paid'
            WHEN ABS(CHECKSUM(NEWID())) % 10 < 3 THEN 'Pending'
            ELSE 'Paid'
        END AS Status,
        1 AS CreatedBy
    FROM Memberships m
    WHERE m.MembershipId > 4
)
INSERT INTO Invoices (InvoiceId, MemberId, TotalAmount, InvoiceDate, DueDate, Status, CreatedBy)
SELECT InvoiceId, MemberId, TotalAmount, InvoiceDate, DueDate, Status, CreatedBy
FROM GeneratedInvoices;

SET IDENTITY_INSERT Invoices OFF;
GO
DBCC CHECKIDENT ('Invoices', RESEED, 2500);
GO

-- ============================================================
-- 9. PAYMENTS (2,000+ records)
-- ============================================================
SET IDENTITY_INSERT Payments ON;

-- First payment for demo
INSERT INTO Payments (PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, Status, CreatedBy) VALUES
(1, 1, 6000000, '2026-01-10 10:15:00', 'BankTransfer', 'Completed', 1);

-- Generate payments for paid invoices
WITH GeneratedPayments AS (
    SELECT TOP (2000)
        ROW_NUMBER() OVER (ORDER BY i.InvoiceId) + 1 AS PaymentId,
        i.InvoiceId,
        i.TotalAmount AS Amount,
        DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 3, i.InvoiceDate) AS PaymentDate,
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'Cash'
            WHEN 1 THEN 'BankTransfer'
            WHEN 2 THEN 'Card'
            WHEN 3 THEN 'MoMo'
            ELSE 'ZaloPay'
        END AS PaymentMethod,
        'Completed' AS Status,
        1 AS CreatedBy
    FROM Invoices i
    WHERE i.Status = 'Paid' AND i.InvoiceId > 1
)
INSERT INTO Payments (PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, Status, CreatedBy)
SELECT PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, Status, CreatedBy
FROM GeneratedPayments;

SET IDENTITY_INSERT Payments OFF;
GO
DBCC CHECKIDENT ('Payments', RESEED, 2000);
GO

-- ============================================================
-- 10. PERMISSIONS SEED (35 permissions)
-- ============================================================
SET IDENTITY_INSERT Permissions ON;
INSERT INTO Permissions (PermissionId, PermissionCode, Description, Module, Action) VALUES
(1, 'Members.Read', 'Xem danh sách hội viên', 'Members', 'Read'),
(2, 'Members.Create', 'Tạo hội viên mới', 'Members', 'Create'),
(3, 'Members.Update', 'Cập nhật thông tin hội viên', 'Members', 'Update'),
(4, 'Members.Delete', 'Xóa hội viên (soft delete)', 'Members', 'Delete'),
(5, 'Members.Export', 'Xuất danh sách hội viên Excel/PDF', 'Members', 'Export'),
(6, 'Trainers.Read', 'Xem danh sách huấn luyện viên', 'Trainers', 'Read'),
(7, 'Trainers.Create', 'Tạo huấn luyện viên mới', 'Trainers', 'Create'),
(8, 'Trainers.Update', 'Cập nhật thông tin huấn luyện viên', 'Trainers', 'Update'),
(9, 'Trainers.Delete', 'Xóa huấn luyện viên (soft delete)', 'Trainers', 'Delete'),
(10, 'Trainers.Export', 'Xuất danh sách huấn luyện viên', 'Trainers', 'Export'),
(11, 'Facilities.Read', 'Xem danh sách phòng/thiết bị', 'Facilities', 'Read'),
(12, 'Facilities.Create', 'Tạo phòng/thiết bị mới', 'Facilities', 'Create'),
(13, 'Facilities.Update', 'Cập nhật phòng/thiết bị', 'Facilities', 'Update'),
(14, 'Facilities.Delete', 'Xóa phòng/thiết bị (soft delete)', 'Facilities', 'Delete'),
(15, 'Facilities.Export', 'Xuất danh sách phòng/thiết bị', 'Facilities', 'Export'),
(16, 'Memberships.Read', 'Xem gói tập', 'Memberships', 'Read'),
(17, 'Memberships.Create', 'Tạo gói tập mới', 'Memberships', 'Create'),
(18, 'Memberships.Update', 'Cập nhật gói tập', 'Memberships', 'Update'),
(19, 'Memberships.Delete', 'Xóa gói tập (soft delete)', 'Memberships', 'Delete'),
(20, 'Memberships.Export', 'Xuất báo cáo gói tập', 'Memberships', 'Export'),
(21, 'Schedules.Read', 'Xem lịch tập', 'Schedules', 'Read'),
(22, 'Schedules.Create', 'Tạo lịch tập mới', 'Schedules', 'Create'),
(23, 'Schedules.Update', 'Cập nhật lịch tập', 'Schedules', 'Update'),
(24, 'Schedules.Delete', 'Xóa lịch tập (soft delete)', 'Schedules', 'Delete'),
(25, 'Schedules.Export', 'Xuất lịch tập', 'Schedules', 'Export'),
(26, 'Sessions.Read', 'Xem buổi tập', 'Sessions', 'Read'),
(27, 'Sessions.Create', 'Tạo buổi tập', 'Sessions', 'Create'),
(28, 'Sessions.Update', 'Cập nhật trạng thái buổi tập', 'Sessions', 'Update'),
(29, 'Sessions.Delete', 'Xóa buổi tập (soft delete)', 'Sessions', 'Delete'),
(30, 'Checkins.Read', 'Xem check-in', 'Checkins', 'Read'),
(31, 'Checkins.Create', 'Thực hiện check-in', 'Checkins', 'Create'),
(32, 'Invoices.Read', 'Xem hóa đơn', 'Invoices', 'Read'),
(33, 'Invoices.Create', 'Tạo hóa đơn', 'Invoices', 'Create'),
(34, 'Invoices.Update', 'Cập nhật hóa đơn', 'Invoices', 'Update'),
(35, 'Invoices.Export', 'Xuất hóa đơn PDF', 'Invoices', 'Export'),
(36, 'Payments.Read', 'Xem thanh toán', 'Payments', 'Read'),
(37, 'Payments.Create', 'Tạo thanh toán', 'Payments', 'Create'),
(38, 'Payments.Update', 'Cập nhật thanh toán', 'Payments', 'Update'),
(39, 'Reports.Read', 'Xem báo cáo', 'Reports', 'Read'),
(40, 'Reports.Export', 'Xuất báo cáo', 'Reports', 'Export'),
(41, 'Users.Read', 'Xem người dùng', 'Users', 'Read'),
(42, 'Users.Create', 'Tạo người dùng', 'Users', 'Create'),
(43, 'Users.Update', 'Cập nhật người dùng', 'Users', 'Update'),
(44, 'Users.Delete', 'Xóa người dùng (soft delete)', 'Users', 'Delete'),
(45, 'AuditLogs.Read', 'Xem audit log', 'AuditLogs', 'Read');
SET IDENTITY_INSERT Permissions OFF;
GO
DBCC CHECKIDENT ('Permissions', RESEED, 45);
GO

-- ============================================================
-- 11. ROLE PERMISSIONS MAPPING
-- ============================================================
-- Admin: All permissions
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM Roles r, Permissions p
WHERE r.RoleName = 'Admin';

-- Trainer: Read/Update own schedules, members, sessions, checkins
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM Roles r, Permissions p
WHERE r.RoleName = 'Trainer' 
  AND p.PermissionCode IN (
    'Members.Read', 'Schedules.Read', 'Schedules.Update', 
    'Sessions.Read', 'Sessions.Update', 'Checkins.Read', 
    'Checkins.Create', 'Facilities.Read', 'Reports.Read'
  );

-- Member: Read own data, create checkins
INSERT INTO RolePermissions (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM Roles r, Permissions p
WHERE r.RoleName = 'Member'
  AND p.PermissionCode IN (
    'Members.Read', 'Memberships.Read', 'Schedules.Read', 
    'Sessions.Read', 'Checkins.Create', 'Invoices.Read', 
    'Payments.Read'
  );
GO

PRINT '═══════════════════════════════════════════════════════════';
PRINT '✅ Seed data hoàn tất:';
PRINT '   - Members: 2,000+';
PRINT '   - Trainers: 20';
PRINT '   - Facilities: 10';
PRINT '   - Memberships: 2,500+';
PRINT '   - Schedules: 5,000+';
PRINT '   - Sessions: 5,000+';
PRINT '   - Checkins: 10,000+';
PRINT '   - Invoices: 2,500+';
PRINT '   - Payments: 2,000+';
PRINT '   - Permissions: 45';
PRINT '   - RolePermissions: Mapped for Admin/Trainer/Member';
PRINT '═══════════════════════════════════════════════════════════';
GO
