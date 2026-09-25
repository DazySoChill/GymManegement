-- ============================================================
-- FILE: 03_SeedData.sql
-- Mô tả: Dữ liệu mẫu (Seed Data) chuẩn để test toàn bộ chức năng
-- ============================================================

USE GymDb;
GO

-- Xoá dữ liệu cũ theo thứ tự khoá ngoại
DELETE FROM Payments;
DELETE FROM Invoices;
DELETE FROM Checkins;
DELETE FROM Sessions;
DELETE FROM Schedules;
DELETE FROM Memberships;
DELETE FROM Facilities;
DELETE FROM Trainers;
DELETE FROM Members;
GO

-- 1. Members
SET IDENTITY_INSERT Members ON;
INSERT INTO Members (MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue) VALUES
(1, N'Nguyễn Văn An',  '0901234567', 'an.nguyen@gmail.com',  '1995-05-15', '2026-01-10', 'Active',   'QR_MEM_001'),
(2, N'Trần Thị Bích',  '0912345678', 'bich.tran@gmail.com',  '1998-08-20', '2026-02-01', 'Active',   'QR_MEM_002'),
(3, N'Lê Hoàng Cường', '0923456789', 'cuong.le@gmail.com',   '1992-11-30', '2026-03-15', 'Active',   'QR_MEM_003'),
(4, N'Phạm Minh Đức',  '0934567890', 'duc.pham@gmail.com',   '2000-02-14', '2026-01-05', 'Inactive', 'QR_MEM_004');
SET IDENTITY_INSERT Members OFF;
GO

-- 2. Trainers
SET IDENTITY_INSERT Trainers ON;
INSERT INTO Trainers (TrainerId, FullName, Phone, Email, Specialization) VALUES
(1, N'Đặng Văn Dũng',  '0987654321', 'dung.pt@gym.com', N'Bodybuilding & Fitness'),
(2, N'Vũ Thị Hoa',     '0976543210', 'hoa.pt@gym.com',  N'Yoga & Pilates'),
(3, N'Hoàng Đình Kiên','0965432109', 'kien.pt@gym.com', N'Boxing & Cardio');
SET IDENTITY_INSERT Trainers OFF;
GO

-- 3. Facilities
SET IDENTITY_INSERT Facilities ON;
INSERT INTO Facilities (FacilityId, Name, Description, IsActive) VALUES
(1, N'Phòng Gym Khu A',        N'Trang thiết bị tạ đơn, giàn tạ khối, máy kéo xô', 1),
(2, N'Phòng Yoga & Pilates',   N'Phòng sàn gỗ cách âm lầu 2, thảm tập & bóng yoga', 1),
(3, N'Sàn Boxing & Cardio',    N'Võ đài đối kháng, bao cát đấm bốc, máy chạy bộ',  1);
SET IDENTITY_INSERT Facilities OFF;
GO

-- 4. Memberships (Gói tập)
SET IDENTITY_INSERT Memberships ON;
INSERT INTO Memberships (MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive) VALUES
(1, 1, 'Annual',    6000000, '2026-01-10', '2027-01-10', 1),
(2, 2, 'Monthly',    600000, '2026-09-01', DATEADD(DAY, 4, CAST(GETDATE() AS DATE)), 1),
(3, 3, 'Quarterly', 1600000, '2026-07-01', DATEADD(DAY, 30, CAST(GETDATE() AS DATE)), 1),
(4, 4, 'Monthly',    500000, '2026-01-05', '2026-02-05', 0);
SET IDENTITY_INSERT Memberships OFF;
GO

-- 5. Schedules (Lịch tập)
SET IDENTITY_INSERT Schedules ON;
INSERT INTO Schedules (ScheduleId, MemberId, TrainerId, FacilityId, StartTime, EndTime) VALUES
(1, 1, 1, 1, DATEADD(HOUR, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(MINUTE, 90, DATEADD(HOUR, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(2, 2, 2, 2, DATEADD(HOUR, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)), DATEADD(MINUTE, 60, DATEADD(HOUR, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))),
(3, 3, 3, 3, DATEADD(DAY, -1, DATEADD(HOUR, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), DATEADD(DAY, -1, DATEADD(MINUTE, 90, DATEADD(HOUR, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))));
SET IDENTITY_INSERT Schedules OFF;
GO

-- 6. Sessions (Buổi tập)
SET IDENTITY_INSERT Sessions ON;
INSERT INTO Sessions (SessionId, ScheduleId, SessionDate, Status) VALUES
(1, 1, CAST(GETDATE() AS DATE), 'Scheduled'),
(2, 2, CAST(GETDATE() AS DATE), 'Scheduled'),
(3, 3, DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), 'Completed');
SET IDENTITY_INSERT Sessions OFF;
GO

-- 7. Checkins
SET IDENTITY_INSERT Checkins ON;
INSERT INTO Checkins (CheckinId, MemberId, SessionId, CheckinTime, CheckinMethod) VALUES
(1, 1, 1, DATEADD(MINUTE, -10, DATEADD(HOUR, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME2))), 'QRCode'),
(2, 3, 3, DATEADD(MINUTE, -5, DATEADD(DAY, -1, DATEADD(HOUR, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME2)))), 'Manual');
SET IDENTITY_INSERT Checkins OFF;
GO

-- 8. Invoices (Hóa đơn)
SET IDENTITY_INSERT Invoices ON;
INSERT INTO Invoices (InvoiceId, MemberId, TotalAmount, InvoiceDate, DueDate, Status) VALUES
(1, 1, 6000000, '2026-01-10', '2026-01-17', 'Paid'),
(2, 2,  600000, CAST(GETDATE() AS DATE), DATEADD(DAY, 7, CAST(GETDATE() AS DATE)), 'Pending'),
(3, 3, 1600000, DATEADD(DAY, -15, CAST(GETDATE() AS DATE)), DATEADD(DAY, -5, CAST(GETDATE() AS DATE)), 'Overdue');
SET IDENTITY_INSERT Invoices OFF;
GO

-- 9. Payments
SET IDENTITY_INSERT Payments ON;
INSERT INTO Payments (PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, Status) VALUES
(1, 1, 6000000, '2026-01-10 10:15:00', 'BankTransfer', 'Completed');
SET IDENTITY_INSERT Payments OFF;
GO

-- Cập nhật IDENTITY lại đúng giá trị max
DBCC CHECKIDENT ('Members', RESEED, 4);
DBCC CHECKIDENT ('Trainers', RESEED, 3);
DBCC CHECKIDENT ('Facilities', RESEED, 3);
DBCC CHECKIDENT ('Memberships', RESEED, 4);
DBCC CHECKIDENT ('Schedules', RESEED, 3);
DBCC CHECKIDENT ('Sessions', RESEED, 3);
DBCC CHECKIDENT ('Checkins', RESEED, 2);
DBCC CHECKIDENT ('Invoices', RESEED, 3);
DBCC CHECKIDENT ('Payments', RESEED, 1);
GO

PRINT 'All Seed Data inserted perfectly!';
