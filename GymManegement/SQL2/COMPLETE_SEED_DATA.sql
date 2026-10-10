-- ============================================================
-- COMPLETE_SEED_DATA.sql
-- Comprehensive seed data for GymDb database
-- ============================================================

USE GymDb;
GO

SET NOCOUNT ON;

PRINT '========================================';
PRINT 'Starting Complete Seed Data...';
PRINT '========================================';
GO

-- ============================================================
-- CLEAR EXISTING DATA (in correct FK order)
-- ============================================================
PRINT 'Clearing existing data...';

DELETE FROM Payments;
DELETE FROM Invoices;
DELETE FROM Checkins;
DELETE FROM Sessions;
DELETE FROM Schedules;
DELETE FROM Memberships;
DELETE FROM Members;
DELETE FROM Facilities;
DELETE FROM Trainers;
DELETE FROM Users;

-- Reset identity seeds
DBCC CHECKIDENT ('Payments', RESEED, 0);
DBCC CHECKIDENT ('Invoices', RESEED, 0);
DBCC CHECKIDENT ('Checkins', RESEED, 0);
DBCC CHECKIDENT ('Sessions', RESEED, 0);
DBCC CHECKIDENT ('Schedules', RESEED, 0);
DBCC CHECKIDENT ('Memberships', RESEED, 0);
DBCC CHECKIDENT ('Members', RESEED, 0);
DBCC CHECKIDENT ('Facilities', RESEED, 0);
DBCC CHECKIDENT ('Trainers', RESEED, 0);
DBCC CHECKIDENT ('Users', RESEED, 0);

PRINT '✓ Data cleared and identity seeds reset';
GO

-- ============================================================
-- 1. USERS TABLE - SuperAdmin
-- ============================================================
PRINT 'Seeding Users table...';

-- BCrypt hash for 'Gym@2026' (using BCrypt WorkFactor 10)
-- Generated hash: $2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
VALUES 
('gymadmin', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'System Administrator', 'admin@gym.com', 'SuperAdmin', 1, GETDATE(), GETDATE(), 0, NULL);

PRINT '✓ SuperAdmin user created';
GO

-- ============================================================
-- 2. TRAINERS TABLE
-- ============================================================
PRINT 'Seeding Trainers table...';

INSERT INTO Trainers (FullName, Phone, Email, Specialization, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
VALUES 
(N'Nguyễn Văn Hùng', '0901234501', 'hung.trainer@gym.com', N'Thể hình & Tăng cơ', GETDATE(), GETDATE(), 0, NULL),
(N'Trần Thị Mai', '0901234502', 'mai.trainer@gym.com', N'Yoga & Pilates', GETDATE(), GETDATE(), 0, NULL),
(N'Lê Minh Tuấn', '0901234503', 'tuan.trainer@gym.com', N'Cardio & Giảm cân', GETDATE(), GETDATE(), 0, NULL),
(N'Phạm Thị Lan', '0901234504', 'lan.trainer@gym.com', N'CrossFit & Functional', GETDATE(), GETDATE(), 0, NULL),
(N'Hoàng Đức Nam', '0901234505', 'nam.trainer@gym.com', N'Boxing & Kickboxing', GETDATE(), GETDATE(), 0, NULL);

PRINT '✓ 5 Trainers created';
GO

-- ============================================================
-- 3. USERS TABLE - Trainer Accounts
-- ============================================================
PRINT 'Seeding Trainer user accounts...';

-- BCrypt hash for 'Trainer@123' 
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
VALUES 
('trainer1', '$2a$10$N9qo8uLOickgx2ZMRZoMye/y5jL8KeOMZPRq.v9jWTWyZIBPXQEE.', N'Nguyễn Văn Hùng', 'hung.trainer@gym.com', 'Trainer', 1, GETDATE(), GETDATE(), 0, NULL),
('trainer2', '$2a$10$N9qo8uLOickgx2ZMRZoMye/y5jL8KeOMZPRq.v9jWTWyZIBPXQEE.', N'Trần Thị Mai', 'mai.trainer@gym.com', 'Trainer', 1, GETDATE(), GETDATE(), 0, NULL),
('trainer3', '$2a$10$N9qo8uLOickgx2ZMRZoMye/y5jL8KeOMZPRq.v9jWTWyZIBPXQEE.', N'Lê Minh Tuấn', 'tuan.trainer@gym.com', 'Trainer', 1, GETDATE(), GETDATE(), 0, NULL),
('trainer4', '$2a$10$N9qo8uLOickgx2ZMRZoMye/y5jL8KeOMZPRq.v9jWTWyZIBPXQEE.', N'Phạm Thị Lan', 'lan.trainer@gym.com', 'Trainer', 1, GETDATE(), GETDATE(), 0, NULL),
('trainer5', '$2a$10$N9qo8uLOickgx2ZMRZoMye/y5jL8KeOMZPRq.v9jWTWyZIBPXQEE.', N'Hoàng Đức Nam', 'nam.trainer@gym.com', 'Trainer', 1, GETDATE(), GETDATE(), 0, NULL);

PRINT '✓ 5 Trainer user accounts created';
GO

-- ============================================================
-- 4. FACILITIES TABLE
-- ============================================================
PRINT 'Seeding Facilities table...';

INSERT INTO Facilities (FacilityName, FacilityType, Capacity, Status, Description, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
VALUES 
-- Rooms
(N'Phòng Tập 1', 'Room', 30, 'Available', N'Phòng tập đa năng, diện tích 100m²', GETDATE(), GETDATE(), 0, NULL),
(N'Phòng Tập 2', 'Room', 25, 'Available', N'Phòng tập Cardio, diện tích 80m²', GETDATE(), GETDATE(), 0, NULL),
(N'Phòng Yoga', 'Room', 20, 'Available', N'Phòng Yoga & Meditation, diện tích 60m²', GETDATE(), GETDATE(), 0, NULL),
(N'Phòng Spinning', 'Room', 15, 'Available', N'Phòng Spinning với 15 xe đạp', GETDATE(), GETDATE(), 0, NULL),
(N'Phòng CrossFit', 'Room', 20, 'Available', N'Khu vực CrossFit & Functional Training', GETDATE(), GETDATE(), 0, NULL),
(N'Phòng Boxing', 'Room', 10, 'Available', N'Khu vực Boxing & Kickboxing', GETDATE(), GETDATE(), 0, NULL),
(N'Phòng VIP 1', 'Room', 5, 'Available', N'Phòng tập riêng VIP', GETDATE(), GETDATE(), 0, NULL),
(N'Phòng VIP 2', 'Room', 5, 'Available', N'Phòng tập riêng VIP', GETDATE(), GETDATE(), 0, NULL),
(N'Khu Tạ', 'Room', 40, 'Available', N'Khu vực tạ tự do & máy tập', GETDATE(), GETDATE(), 0, NULL),
(N'Khu Cardio', 'Room', 30, 'Available', N'Khu máy chạy bộ, xe đạp, máy chèo', GETDATE(), GETDATE(), 0, NULL),
-- Equipment
(N'Máy Chạy Bộ', 'Equipment', NULL, 'Available', N'TechnoGym Run 700', GETDATE(), GETDATE(), 0, NULL),
(N'Xe Đạp Tập', 'Equipment', NULL, 'Available', N'Life Fitness IC7', GETDATE(), GETDATE(), 0, NULL),
(N'Máy Chèo', 'Equipment', NULL, 'Available', N'Concept2 Model D', GETDATE(), GETDATE(), 0, NULL),
(N'Máy Tập Ngực', 'Equipment', NULL, 'Available', N'Life Fitness Chest Press', GETDATE(), GETDATE(), 0, NULL),
(N'Máy Tập Vai', 'Equipment', NULL, 'Available', N'Precor Shoulder Press', GETDATE(), GETDATE(), 0, NULL),
(N'Máy Tập Chân', 'Equipment', NULL, 'Available', N'Cybex Leg Press', GETDATE(), GETDATE(), 0, NULL),
(N'Máy Tập Lưng', 'Equipment', NULL, 'Available', N'Hammer Strength Row', GETDATE(), GETDATE(), 0, NULL),
(N'Xà Đơn', 'Equipment', NULL, 'Available', N'Pull-up Bar Station', GETDATE(), GETDATE(), 0, NULL),
(N'Ghế Tập Bụng', 'Equipment', NULL, 'Available', N'Adjustable Ab Bench', GETDATE(), GETDATE(), 0, NULL),
(N'Bộ Tạ Tay', 'Equipment', NULL, 'Available', N'Dumbbell Set 1-50kg', GETDATE(), GETDATE(), 0, NULL);

PRINT '✓ 20 Facilities created (10 Rooms + 10 Equipment)';
GO

-- ============================================================
-- 5. MEMBERS TABLE
-- ============================================================
PRINT 'Seeding Members table...';

INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
VALUES 
(N'Nguyễn Thị Hoa', 'hoa.nguyen@gmail.com', '0912345001', '1995-01-15', 'M000001', GETDATE(), GETDATE(), 0, NULL),
(N'Trần Văn Nam', 'nam.tran@gmail.com', '0912345002', '1992-03-20', 'M000002', GETDATE(), GETDATE(), 0, NULL),
(N'Lê Thị Lan', 'lan.le@gmail.com', '0912345003', '1998-06-10', 'M000003', GETDATE(), GETDATE(), 0, NULL),
(N'Phạm Minh Tuấn', 'tuan.pham@gmail.com', '0912345004', '1990-11-05', 'M000004', GETDATE(), GETDATE(), 0, NULL),
(N'Hoàng Thị Mai', 'mai.hoang@gmail.com', '0912345005', '1997-08-22', 'M000005', GETDATE(), GETDATE(), 0, NULL),
(N'Vũ Văn Hùng', 'hung.vu@gmail.com', '0912345006', '1994-02-14', 'M000006', GETDATE(), GETDATE(), 0, NULL),
(N'Đỗ Thị Phương', 'phuong.do@gmail.com', '0912345007', '1996-04-18', 'M000007', GETDATE(), GETDATE(), 0, NULL),
(N'Bùi Văn Đức', 'duc.bui@gmail.com', '0912345008', '1991-09-30', 'M000008', GETDATE(), GETDATE(), 0, NULL),
(N'Đinh Thị Hương', 'huong.dinh@gmail.com', '0912345009', '1999-12-01', 'M000009', GETDATE(), GETDATE(), 0, NULL),
(N'Lý Văn Khánh', 'khanh.ly@gmail.com', '0912345010', '1993-07-25', 'M000010', GETDATE(), GETDATE(), 0, NULL),
(N'Võ Thị Nga', 'nga.vo@gmail.com', '0912345011', '1995-05-12', 'M000011', GETDATE(), GETDATE(), 0, NULL),
(N'Ngô Văn Tài', 'tai.ngo@gmail.com', '0912345012', '1989-10-08', 'M000012', GETDATE(), GETDATE(), 0, NULL),
(N'Dương Thị Bích', 'bich.duong@gmail.com', '0912345013', '1998-01-30', 'M000013', GETDATE(), GETDATE(), 0, NULL),
(N'Tô Văn Dũng', 'dung.to@gmail.com', '0912345014', '1992-06-17', 'M000014', GETDATE(), GETDATE(), 0, NULL),
(N'Hồ Thị Yến', 'yen.ho@gmail.com', '0912345015', '1997-11-22', 'M000015', GETDATE(), GETDATE(), 0, NULL),
(N'Trịnh Văn Bình', 'binh.trinh@gmail.com', '0912345016', '1994-03-09', 'M000016', GETDATE(), GETDATE(), 0, NULL),
(N'Lưu Thị Cúc', 'cuc.luu@gmail.com', '0912345017', '1996-08-14', 'M000017', GETDATE(), GETDATE(), 0, NULL),
(N'Mai Văn Sơn', 'son.mai@gmail.com', '0912345018', '1990-12-28', 'M000018', GETDATE(), GETDATE(), 0, NULL),
(N'Phan Thị Diệu', 'dieu.phan@gmail.com', '0912345019', '1999-04-06', 'M000019', GETDATE(), GETDATE(), 0, NULL),
(N'Cao Văn Hải', 'hai.cao@gmail.com', '0912345020', '1993-09-11', 'M000020', GETDATE(), GETDATE(), 0, NULL),
(N'Đặng Thị Thảo', 'thao.dang@gmail.com', '0912345021', '1995-07-19', 'M000021', GETDATE(), GETDATE(), 0, NULL),
(N'Huỳnh Văn Phúc', 'phuc.huynh@gmail.com', '0912345022', '1991-02-26', 'M000022', GETDATE(), GETDATE(), 0, NULL),
(N'Thái Thị Xuân', 'xuan.thai@gmail.com', '0912345023', '1998-10-03', 'M000023', GETDATE(), GETDATE(), 0, NULL),
(N'Lâm Văn Quân', 'quan.lam@gmail.com', '0912345024', '1992-05-21', 'M000024', GETDATE(), GETDATE(), 0, NULL),
(N'Đoàn Thị Thu', 'thu.doan@gmail.com', '0912345025', '1997-01-07', 'M000025', GETDATE(), GETDATE(), 0, NULL),
(N'Tạ Văn Minh', 'minh.ta@gmail.com', '0912345026', '1994-06-13', 'M000026', GETDATE(), GETDATE(), 0, NULL),
(N'Ông Thị Hằng', 'hang.ong@gmail.com', '0912345027', '1996-11-29', 'M000027', GETDATE(), GETDATE(), 0, NULL),
(N'La Văn Thắng', 'thang.la@gmail.com', '0912345028', '1990-04-16', 'M000028', GETDATE(), GETDATE(), 0, NULL),
(N'Khương Thị Linh', 'linh.khuong@gmail.com', '0912345029', '1999-08-24', 'M000029', GETDATE(), GETDATE(), 0, NULL),
(N'Sầm Văn Toàn', 'toan.sam@gmail.com', '0912345030', '1993-12-31', 'M000030', GETDATE(), GETDATE(), 0, NULL);

PRINT '✓ 30 Members created';
GO

-- ============================================================
-- 6. USERS TABLE - Member Accounts
-- ============================================================
PRINT 'Seeding Member user accounts...';

-- BCrypt hash for 'Member@123'
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, MemberId, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
VALUES 
('member1', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Nguyễn Thị Hoa', 'hoa.nguyen@gmail.com', 'Member', 1, 1, GETDATE(), GETDATE(), 0, NULL),
('member2', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Trần Văn Nam', 'nam.tran@gmail.com', 'Member', 1, 2, GETDATE(), GETDATE(), 0, NULL),
('member3', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Lê Thị Lan', 'lan.le@gmail.com', 'Member', 1, 3, GETDATE(), GETDATE(), 0, NULL),
('member4', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Phạm Minh Tuấn', 'tuan.pham@gmail.com', 'Member', 1, 4, GETDATE(), GETDATE(), 0, NULL),
('member5', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Hoàng Thị Mai', 'mai.hoang@gmail.com', 'Member', 1, 5, GETDATE(), GETDATE(), 0, NULL),
('member6', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Vũ Văn Hùng', 'hung.vu@gmail.com', 'Member', 1, 6, GETDATE(), GETDATE(), 0, NULL),
('member7', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Đỗ Thị Phương', 'phuong.do@gmail.com', 'Member', 1, 7, GETDATE(), GETDATE(), 0, NULL),
('member8', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Bùi Văn Đức', 'duc.bui@gmail.com', 'Member', 1, 8, GETDATE(), GETDATE(), 0, NULL),
('member9', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Đinh Thị Hương', 'huong.dinh@gmail.com', 'Member', 1, 9, GETDATE(), GETDATE(), 0, NULL),
('member10', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Lý Văn Khánh', 'khanh.ly@gmail.com', 'Member', 1, 10, GETDATE(), GETDATE(), 0, NULL),
('member11', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Võ Thị Nga', 'nga.vo@gmail.com', 'Member', 1, 11, GETDATE(), GETDATE(), 0, NULL),
('member12', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Ngô Văn Tài', 'tai.ngo@gmail.com', 'Member', 1, 12, GETDATE(), GETDATE(), 0, NULL),
('member13', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Dương Thị Bích', 'bich.duong@gmail.com', 'Member', 1, 13, GETDATE(), GETDATE(), 0, NULL),
('member14', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Tô Văn Dũng', 'dung.to@gmail.com', 'Member', 1, 14, GETDATE(), GETDATE(), 0, NULL),
('member15', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Hồ Thị Yến', 'yen.ho@gmail.com', 'Member', 1, 15, GETDATE(), GETDATE(), 0, NULL),
('member16', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Trịnh Văn Bình', 'binh.trinh@gmail.com', 'Member', 1, 16, GETDATE(), GETDATE(), 0, NULL),
('member17', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Lưu Thị Cúc', 'cuc.luu@gmail.com', 'Member', 1, 17, GETDATE(), GETDATE(), 0, NULL),
('member18', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Mai Văn Sơn', 'son.mai@gmail.com', 'Member', 1, 18, GETDATE(), GETDATE(), 0, NULL),
('member19', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Phan Thị Diệu', 'dieu.phan@gmail.com', 'Member', 1, 19, GETDATE(), GETDATE(), 0, NULL),
('member20', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Cao Văn Hải', 'hai.cao@gmail.com', 'Member', 1, 20, GETDATE(), GETDATE(), 0, NULL),
('member21', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Đặng Thị Thảo', 'thao.dang@gmail.com', 'Member', 1, 21, GETDATE(), GETDATE(), 0, NULL),
('member22', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Huỳnh Văn Phúc', 'phuc.huynh@gmail.com', 'Member', 1, 22, GETDATE(), GETDATE(), 0, NULL),
('member23', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Thái Thị Xuân', 'xuan.thai@gmail.com', 'Member', 1, 23, GETDATE(), GETDATE(), 0, NULL),
('member24', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Lâm Văn Quân', 'quan.lam@gmail.com', 'Member', 1, 24, GETDATE(), GETDATE(), 0, NULL),
('member25', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Đoàn Thị Thu', 'thu.doan@gmail.com', 'Member', 1, 25, GETDATE(), GETDATE(), 0, NULL),
('member26', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Tạ Văn Minh', 'minh.ta@gmail.com', 'Member', 1, 26, GETDATE(), GETDATE(), 0, NULL),
('member27', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Ông Thị Hằng', 'hang.ong@gmail.com', 'Member', 1, 27, GETDATE(), GETDATE(), 0, NULL),
('member28', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'La Văn Thắng', 'thang.la@gmail.com', 'Member', 1, 28, GETDATE(), GETDATE(), 0, NULL),
('member29', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Khương Thị Linh', 'linh.khuong@gmail.com', 'Member', 1, 29, GETDATE(), GETDATE(), 0, NULL),
('member30', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y0P8K9P.qKE3eXjHjB8JMCvKB9aYG', N'Sầm Văn Toàn', 'toan.sam@gmail.com', 'Member', 1, 30, GETDATE(), GETDATE(), 0, NULL);

PRINT '✓ 30 Member user accounts created';
GO

-- ============================================================
-- 7. MEMBERSHIPS TABLE
-- ============================================================
PRINT 'Seeding Memberships table...';

INSERT INTO Memberships (MemberId, PackageName, Price, StartDate, EndDate, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
VALUES 
-- Active memberships (EndDate >= today)
(1, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -15, GETDATE()), DATEADD(DAY, 15, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(2, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -30, GETDATE()), DATEADD(DAY, 60, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(3, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -45, GETDATE()), DATEADD(DAY, 135, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(4, N'Gói VIP 1 Năm', 2999000, DATEADD(DAY, -60, GETDATE()), DATEADD(DAY, 305, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(5, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -10, GETDATE()), DATEADD(DAY, 20, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(6, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -20, GETDATE()), DATEADD(DAY, 70, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(7, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -90, GETDATE()), DATEADD(DAY, 90, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(8, N'Gói VIP 1 Năm', 2999000, DATEADD(DAY, -180, GETDATE()), DATEADD(DAY, 185, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(9, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, 25, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(10, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -40, GETDATE()), DATEADD(DAY, 50, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(11, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -12, GETDATE()), DATEADD(DAY, 18, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(12, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -25, GETDATE()), DATEADD(DAY, 65, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(13, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -50, GETDATE()), DATEADD(DAY, 130, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(14, N'Gói VIP 1 Năm', 2999000, DATEADD(DAY, -100, GETDATE()), DATEADD(DAY, 265, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(15, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -8, GETDATE()), DATEADD(DAY, 22, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(16, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -35, GETDATE()), DATEADD(DAY, 55, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(17, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -70, GETDATE()), DATEADD(DAY, 110, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(18, N'Gói VIP 1 Năm', 2999000, DATEADD(DAY, -150, GETDATE()), DATEADD(DAY, 215, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(19, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -3, GETDATE()), DATEADD(DAY, 27, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(20, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -28, GETDATE()), DATEADD(DAY, 62, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(21, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -14, GETDATE()), DATEADD(DAY, 16, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(22, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -22, GETDATE()), DATEADD(DAY, 68, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(23, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -55, GETDATE()), DATEADD(DAY, 125, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(24, N'Gói VIP 1 Năm', 2999000, DATEADD(DAY, -120, GETDATE()), DATEADD(DAY, 245, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
(25, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -6, GETDATE()), DATEADD(DAY, 24, GETDATE()), GETDATE(), GETDATE(), 0, NULL),
-- Expired memberships (EndDate < today)
(26, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -45, GETDATE()), DATEADD(DAY, -15, GETDATE()), DATEADD(DAY, -45, GETDATE()), GETDATE(), 0, NULL),
(27, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -150, GETDATE()), DATEADD(DAY, -60, GETDATE()), DATEADD(DAY, -150, GETDATE()), GETDATE(), 0, NULL),
(28, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -250, GETDATE()), DATEADD(DAY, -70, GETDATE()), DATEADD(DAY, -250, GETDATE()), GETDATE(), 0, NULL),
(29, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -50, GETDATE()), DATEADD(DAY, -20, GETDATE()), DATEADD(DAY, -50, GETDATE()), GETDATE(), 0, NULL),
(30, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -180, GETDATE()), DATEADD(DAY, -90, GETDATE()), DATEADD(DAY, -180, GETDATE()), GETDATE(), 0, NULL),
-- Additional memberships for variety
(1, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -120, GETDATE()), DATEADD(DAY, -30, GETDATE()), DATEADD(DAY, -120, GETDATE()), GETDATE(), 0, NULL),
(2, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -90, GETDATE()), DATEADD(DAY, -60, GETDATE()), DATEADD(DAY, -90, GETDATE()), GETDATE(), 0, NULL),
(3, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -140, GETDATE()), DATEADD(DAY, -110, GETDATE()), DATEADD(DAY, -140, GETDATE()), GETDATE(), 0, NULL),
(4, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -200, GETDATE()), DATEADD(DAY, -110, GETDATE()), DATEADD(DAY, -200, GETDATE()), GETDATE(), 0, NULL),
(5, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -260, GETDATE()), DATEADD(DAY, -80, GETDATE()), DATEADD(DAY, -260, GETDATE()), GETDATE(), 0, NULL),
(6, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -110, GETDATE()), DATEADD(DAY, -80, GETDATE()), DATEADD(DAY, -110, GETDATE()), GETDATE(), 0, NULL),
(7, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -270, GETDATE()), DATEADD(DAY, -180, GETDATE()), DATEADD(DAY, -270, GETDATE()), GETDATE(), 0, NULL),
(8, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -400, GETDATE()), DATEADD(DAY, -370, GETDATE()), DATEADD(DAY, -400, GETDATE()), GETDATE(), 0, NULL),
(9, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -160, GETDATE()), DATEADD(DAY, -70, GETDATE()), DATEADD(DAY, -160, GETDATE()), GETDATE(), 0, NULL),
(10, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -300, GETDATE()), DATEADD(DAY, -120, GETDATE()), DATEADD(DAY, -300, GETDATE()), GETDATE(), 0, NULL),
(11, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -170, GETDATE()), DATEADD(DAY, -80, GETDATE()), DATEADD(DAY, -170, GETDATE()), GETDATE(), 0, NULL),
(12, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -85, GETDATE()), DATEADD(DAY, -55, GETDATE()), DATEADD(DAY, -85, GETDATE()), GETDATE(), 0, NULL),
(13, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -130, GETDATE()), DATEADD(DAY, -100, GETDATE()), DATEADD(DAY, -130, GETDATE()), GETDATE(), 0, NULL),
(14, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -320, GETDATE()), DATEADD(DAY, -230, GETDATE()), DATEADD(DAY, -320, GETDATE()), GETDATE(), 0, NULL),
(15, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -280, GETDATE()), DATEADD(DAY, -100, GETDATE()), DATEADD(DAY, -280, GETDATE()), GETDATE(), 0, NULL),
(16, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -95, GETDATE()), DATEADD(DAY, -65, GETDATE()), DATEADD(DAY, -95, GETDATE()), GETDATE(), 0, NULL),
(17, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -250, GETDATE()), DATEADD(DAY, -160, GETDATE()), DATEADD(DAY, -250, GETDATE()), GETDATE(), 0, NULL),
(18, N'Gói Cơ Bản 1 Tháng', 299000, DATEADD(DAY, -330, GETDATE()), DATEADD(DAY, -300, GETDATE()), DATEADD(DAY, -330, GETDATE()), GETDATE(), 0, NULL),
(19, N'Gói Tiêu Chuẩn 3 Tháng', 799000, DATEADD(DAY, -145, GETDATE()), DATEADD(DAY, -55, GETDATE()), DATEADD(DAY, -145, GETDATE()), GETDATE(), 0, NULL),
(20, N'Gói Cao Cấp 6 Tháng', 1499000, DATEADD(DAY, -310, GETDATE()), DATEADD(DAY, -130, GETDATE()), DATEADD(DAY, -310, GETDATE()), GETDATE(), 0, NULL);

PRINT '✓ 50 Memberships created (25 active + 25 expired)';
GO

-- ============================================================
-- 8. SCHEDULES TABLE
-- ============================================================
PRINT 'Seeding Schedules table...';

-- Next 30 days of classes
DECLARE @ScheduleDate DATETIME2 = GETDATE();
DECLARE @i INT = 0;

WHILE @i < 30
BEGIN
    -- Morning classes (6 AM - 12 PM)
    INSERT INTO Schedules (TrainerId, FacilityId, ClassName, StartTime, EndTime, MaxCapacity, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
    VALUES 
    (1, 1, N'Thể Hình Sáng', DATEADD(HOUR, 6, @ScheduleDate), DATEADD(HOUR, 8, @ScheduleDate), 20, GETDATE(), GETDATE(), 0, NULL),
    (2, 3, N'Yoga Buổi Sáng', DATEADD(HOUR, 7, @ScheduleDate), DATEADD(HOUR, 8, @ScheduleDate), 15, GETDATE(), GETDATE(), 0, NULL),
    (3, 2, N'Cardio Morning', DATEADD(HOUR, 8, @ScheduleDate), DATEADD(HOUR, 9, @ScheduleDate), 25, GETDATE(), GETDATE(), 0, NULL),
    
    -- Afternoon classes (12 PM - 6 PM)
    (4, 5, N'CrossFit Chiều', DATEADD(HOUR, 14, @ScheduleDate), DATEADD(HOUR, 15, @ScheduleDate), 18, GETDATE(), GETDATE(), 0, NULL),
    (5, 6, N'Boxing Chiều', DATEADD(HOUR, 16, @ScheduleDate), DATEADD(HOUR, 17, @ScheduleDate), 12, GETDATE(), GETDATE(), 0, NULL),
    
    -- Evening classes (6 PM - 10 PM)
    (1, 1, N'Thể Hình Tối', DATEADD(HOUR, 18, @ScheduleDate), DATEADD(HOUR, 20, @ScheduleDate), 20, GETDATE(), GETDATE(), 0, NULL),
    (2, 3, N'Yoga Buổi Tối', DATEADD(HOUR, 19, @ScheduleDate), DATEADD(HOUR, 20, @ScheduleDate), 15, GETDATE(), GETDATE(), 0, NULL),
    (3, 4, N'Spinning Night', DATEADD(HOUR, 20, @ScheduleDate), DATEADD(HOUR, 21, @ScheduleDate), 15, GETDATE(), GETDATE(), 0, NULL);
    
    SET @ScheduleDate = DATEADD(DAY, 1, @ScheduleDate);
    SET @i = @i + 1;
END

PRINT '✓ 240 Schedules created (30 days × 8 classes/day)';
GO

-- ============================================================
-- 9. SESSIONS TABLE (Member registrations for schedules)
-- ============================================================
PRINT 'Seeding Sessions table...';

-- Register members to various schedules (first 60 schedules for demonstration)
-- Note: Only seeding first 60 out of 240 schedules to avoid excessive data
DECLARE @SessionScheduleId INT = 1;
DECLARE @SessionMemberId INT;
DECLARE @j INT = 0;

WHILE @SessionScheduleId <= 60
BEGIN
    -- Register 3-5 random members to each schedule
    SET @SessionMemberId = 1;
    WHILE @SessionMemberId <= 5
    BEGIN
        INSERT INTO Sessions (ScheduleId, MemberId, RegistrationDate, Status, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
        VALUES 
        (@SessionScheduleId, @SessionMemberId, DATEADD(DAY, -3, GETDATE()), 'Registered', GETDATE(), GETDATE(), 0, NULL);
        
        SET @SessionMemberId = @SessionMemberId + 1;
    END
    
    -- Some attended
    SET @SessionMemberId = 6;
    WHILE @SessionMemberId <= 10
    BEGIN
        INSERT INTO Sessions (ScheduleId, MemberId, RegistrationDate, Status, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
        VALUES 
        (@SessionScheduleId, @SessionMemberId, DATEADD(DAY, -5, GETDATE()), 'Attended', GETDATE(), GETDATE(), 0, NULL);
        
        SET @SessionMemberId = @SessionMemberId + 1;
    END
    
    SET @SessionScheduleId = @SessionScheduleId + 1;
END

PRINT '✓ 600 Sessions created (60 schedules × 10 registrations each, remaining schedules have no registrations yet)';
GO

-- ============================================================
-- 10. CHECKINS TABLE
-- ============================================================
PRINT 'Seeding Checkins table...';

-- Checkins for last 30 days
DECLARE @CheckinDate DATETIME2 = DATEADD(DAY, -30, GETDATE());
DECLARE @CheckinMemberId INT;
DECLARE @k INT = 0;

WHILE @k < 100
BEGIN
    SET @CheckinMemberId = (@k % 20) + 1; -- Rotate through first 20 members
    SET @CheckinDate = DATEADD(HOUR, FLOOR(RAND() * 14) + 6, DATEADD(DAY, FLOOR(RAND() * 30), DATEADD(DAY, -30, GETDATE()))); -- Random time between 6 AM - 8 PM, random day in last 30 days
    
    -- 80% have checkout time
    IF @k % 5 <> 0
    BEGIN
        INSERT INTO Checkins (MemberId, CheckinTime, CheckoutTime, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
        VALUES 
        (@CheckinMemberId, @CheckinDate, DATEADD(HOUR, FLOOR(RAND() * 2) + 1, @CheckinDate), GETDATE(), GETDATE(), 0, NULL);
    END
    ELSE
    BEGIN
        INSERT INTO Checkins (MemberId, CheckinTime, CheckoutTime, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
        VALUES 
        (@CheckinMemberId, @CheckinDate, NULL, GETDATE(), GETDATE(), 0, NULL);
    END
    
    SET @k = @k + 1;
END

PRINT '✓ 100 Checkins created';
GO

-- ============================================================
-- 11. INVOICES TABLE
-- ============================================================
PRINT 'Seeding Invoices table...';

-- Create invoices for all memberships
INSERT INTO Invoices (MemberId, MembershipId, TotalAmount, InvoiceDate, DueDate, Status, Description, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
SELECT 
    m.MemberId,
    m.MembershipId,
    m.Price,
    m.StartDate,
    m.EndDate,
    CASE 
        WHEN m.EndDate < CAST(GETDATE() AS DATE) THEN 'Paid'
        WHEN m.EndDate >= CAST(GETDATE() AS DATE) THEN 'Paid'
        ELSE 'Pending'
    END,
    N'Hóa đơn gói tập ' + m.PackageName,
    m.CreatedAt,
    m.UpdatedAt,
    0,
    NULL
FROM Memberships m
WHERE m.IsDeleted = 0;

PRINT '✓ 50 Invoices created (one per membership)';
GO

-- ============================================================
-- 12. PAYMENTS TABLE
-- ============================================================
PRINT 'Seeding Payments table...';

-- Create payments for all invoices
INSERT INTO Payments (InvoiceId, MemberId, Amount, PaymentDate, PaymentMethod, TransactionId, Status, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
SELECT 
    i.InvoiceId,
    i.MemberId,
    i.TotalAmount,
    i.InvoiceDate,
    CASE 
        WHEN i.InvoiceId % 3 = 0 THEN 'Cash'
        WHEN i.InvoiceId % 3 = 1 THEN 'Card'
        ELSE 'QRCode'
    END,
    CASE 
        WHEN i.InvoiceId % 3 = 0 THEN 'CASH_' + CAST(i.InvoiceId AS NVARCHAR(10))
        WHEN i.InvoiceId % 3 = 1 THEN 'CARD_' + CAST(i.InvoiceId AS NVARCHAR(10))
        ELSE 'QR_' + CAST(i.InvoiceId AS NVARCHAR(10))
    END,
    'Completed',
    i.InvoiceDate,
    i.UpdatedAt,
    0,
    NULL
FROM Invoices i
WHERE i.Status = 'Paid' AND i.IsDeleted = 0;

PRINT '✓ 50 Payments created';
GO

PRINT '========================================';
PRINT '✅ Complete Seed Data Done!';
PRINT '========================================';
PRINT 'Summary:';
PRINT '  - 1 SuperAdmin';
PRINT '  - 5 Trainers + 5 Trainer Users';
PRINT '  - 20 Facilities';
PRINT '  - 30 Members + 30 Member Users';
PRINT '  - 50 Memberships';
PRINT '  - 240 Schedules';
PRINT '  - 600 Sessions';
PRINT '  - 100 Checkins';
PRINT '  - 50 Invoices';
PRINT '  - 50 Payments';
PRINT '========================================';
GO
