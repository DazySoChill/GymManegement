-- =============================================
-- FILE: 14_SEED_DATA.sql
-- PURPOSE: Insert seed/sample data for all tables
-- DESCRIPTION: Populates the database with test data including users, trainers,
--              members, facilities, memberships, schedules, sessions, checkins,
--              invoices, payments, preferences, and audit logs
-- IMPORTANT: All N'...' prefixes MUST be preserved for Vietnamese text support
-- =============================================

USE GymDb;
GO

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
