-- =============================================
-- GymManagement Database Seed Data
-- Realistic Vietnamese data for testing
-- =============================================

-- 1. INSERT USERS (Admin + Trainers + Members)
-- Password hash: $2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi (bcrypt for 'password')

-- Admin user (ID will be 1)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
('admin', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Quản Trị Viên', 'admin@gymmanagement.vn', 'Admin', 1, GETDATE(), GETDATE(), 0);

-- Trainer users (IDs will be 2-6)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
('trainer1', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Nguyễn Văn An', 'an.nguyen@gymmanagement.vn', 'Trainer', 1, GETDATE(), GETDATE(), 0),
('trainer2', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Trần Thị Bình', 'binh.tran@gymmanagement.vn', 'Trainer', 1, GETDATE(), GETDATE(), 0),
('trainer3', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Lê Minh Cường', 'cuong.le@gymmanagement.vn', 'Trainer', 1, GETDATE(), GETDATE(), 0),
('trainer4', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Phạm Thu Duyên', 'duyen.pham@gymmanagement.vn', 'Trainer', 1, GETDATE(), GETDATE(), 0),
('trainer5', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Hoàng Quốc Huy', 'huy.hoang@gymmanagement.vn', 'Trainer', 1, GETDATE(), GETDATE(), 0);

-- Member users (IDs will be 7-26)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
('member01', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Nguyễn Thị Mai', 'mai.nguyen@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member02', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Trần Văn Nam', 'nam.tran@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member03', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Lê Thị Oanh', 'oanh.le@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member04', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Phạm Văn Phúc', 'phuc.pham@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member05', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Hoàng Thị Quỳnh', 'quynh.hoang@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member06', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Vũ Văn Rồng', 'rong.vu@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member07', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Đỗ Thị Sương', 'suong.do@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member08', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Bùi Văn Tài', 'tai.bui@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member09', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Ngô Thị Uyên', 'uyen.ngo@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member10', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Đinh Văn Vinh', 'vinh.dinh@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member11', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Đặng Thị Xuân', 'xuan.dang@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member12', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Cao Văn Yên', 'yen.cao@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member13', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Lưu Thị Ánh', 'anh.luu@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member14', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Dương Văn Bảo', 'bao.duong@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member15', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Phan Thị Chi', 'chi.phan@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member16', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Võ Văn Đức', 'duc.vo@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member17', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Trương Thị Em', 'em.truong@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member18', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Hồ Văn Phong', 'phong.ho@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member19', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Tô Thị Giang', 'giang.to@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0),
('member20', '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Lý Văn Hào', 'hao.ly@gmail.com', 'Member', 1, GETDATE(), GETDATE(), 0);

-- 2. INSERT TRAINERS (matching trainer users)
INSERT INTO Trainers (FullName, Email, Phone, Specialization, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Nguyễn Văn An', 'an.nguyen@gymmanagement.vn', '0901234567', N'Gym & Fitness', GETDATE(), GETDATE(), 0),
(N'Trần Thị Bình', 'binh.tran@gymmanagement.vn', '0901234568', N'Yoga & Pilates', GETDATE(), GETDATE(), 0),
(N'Lê Minh Cường', 'cuong.le@gymmanagement.vn', '0901234569', N'Cardio & HIIT', GETDATE(), GETDATE(), 0),
(N'Phạm Thu Duyên', 'duyen.pham@gymmanagement.vn', '0901234570', N'Aerobic & Dance', GETDATE(), GETDATE(), 0),
(N'Hoàng Quốc Huy', 'huy.hoang@gymmanagement.vn', '0901234571', N'Boxing & Martial Arts', GETDATE(), GETDATE(), 0);

-- 3. INSERT MEMBERS (matching member users)
INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Nguyễn Thị Mai', 'mai.nguyen@gmail.com', '0912345601', '1995-03-15', 'M000001', GETDATE(), GETDATE(), 0),
(N'Trần Văn Nam', 'nam.tran@gmail.com', '0912345602', '1992-07-20', 'M000002', GETDATE(), GETDATE(), 0),
(N'Lê Thị Oanh', 'oanh.le@gmail.com', '0912345603', '1998-11-05', 'M000003', GETDATE(), GETDATE(), 0),
(N'Phạm Văn Phúc', 'phuc.pham@gmail.com', '0912345604', '1990-01-10', 'M000004', GETDATE(), GETDATE(), 0),
(N'Hoàng Thị Quỳnh', 'quynh.hoang@gmail.com', '0912345605', '1997-05-25', 'M000005', GETDATE(), GETDATE(), 0),
(N'Vũ Văn Rồng', 'rong.vu@gmail.com', '0912345606', '1993-09-30', 'M000006', GETDATE(), GETDATE(), 0),
(N'Đỗ Thị Sương', 'suong.do@gmail.com', '0912345607', '1996-02-14', 'M000007', GETDATE(), GETDATE(), 0),
(N'Bùi Văn Tài', 'tai.bui@gmail.com', '0912345608', '1991-06-18', 'M000008', GETDATE(), GETDATE(), 0),
(N'Ngô Thị Uyên', 'uyen.ngo@gmail.com', '0912345609', '1999-12-22', 'M000009', GETDATE(), GETDATE(), 0),
(N'Đinh Văn Vinh', 'vinh.dinh@gmail.com', '0912345610', '1994-04-08', 'M000010', GETDATE(), GETDATE(), 0),
(N'Đặng Thị Xuân', 'xuan.dang@gmail.com', '0912345611', '1995-08-12', 'M000011', GETDATE(), GETDATE(), 0),
(N'Cao Văn Yên', 'yen.cao@gmail.com', '0912345612', '1992-10-28', 'M000012', GETDATE(), GETDATE(), 0),
(N'Lưu Thị Ánh', 'anh.luu@gmail.com', '0912345613', '1997-03-03', 'M000013', GETDATE(), GETDATE(), 0),
(N'Dương Văn Bảo', 'bao.duong@gmail.com', '0912345614', '1990-07-17', 'M000014', GETDATE(), GETDATE(), 0),
(N'Phan Thị Chi', 'chi.phan@gmail.com', '0912345615', '1998-11-21', 'M000015', GETDATE(), GETDATE(), 0),
(N'Võ Văn Đức', 'duc.vo@gmail.com', '0912345616', '1993-01-26', 'M000016', GETDATE(), GETDATE(), 0),
(N'Trương Thị Em', 'em.truong@gmail.com', '0912345617', '1996-05-09', 'M000017', GETDATE(), GETDATE(), 0),
(N'Hồ Văn Phong', 'phong.ho@gmail.com', '0912345618', '1991-09-13', 'M000018', GETDATE(), GETDATE(), 0),
(N'Tô Thị Giang', 'giang.to@gmail.com', '0912345619', '1999-02-27', 'M000019', GETDATE(), GETDATE(), 0),
(N'Lý Văn Hào', 'hao.ly@gmail.com', '0912345620', '1994-06-04', 'M000020', GETDATE(), GETDATE(), 0);

-- 4. INSERT FACILITIES
INSERT INTO Facilities (Name, Description, Status, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Phòng Gym Tầng 1', N'Phòng tập gym chính với đầy đủ thiết bị hiện đại', 'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Yoga', N'Phòng tập yoga yên tĩnh, thoáng mát', 'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Cardio', N'Phòng tập cardio với máy chạy bộ, xe đạp', 'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Aerobic', N'Phòng tập aerobic rộng rãi với hệ thống âm thanh tốt', 'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Boxing', N'Phòng tập boxing với bao cát và sàn đấu', 'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Gym Tầng 2', N'Phòng gym phụ với thiết bị tạ tự do', 'Available', GETDATE(), GETDATE(), 0),
(N'Sân Tennis', N'Sân tennis ngoài trời', 'Maintenance', GETDATE(), GETDATE(), 0),
(N'Phòng Pilates', N'Phòng tập pilates chuyên nghiệp', 'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Spinning', N'Phòng tập spinning với 20 xe đạp', 'Available', GETDATE(), GETDATE(), 0),
(N'Phòng Đa Năng', N'Phòng đa năng cho các lớp học nhóm', 'Available', GETDATE(), GETDATE(), 0);

-- 5. INSERT MEMBERSHIPS
INSERT INTO Memberships (MemberId, PackageName, Price, StartDate, EndDate, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, N'Gói Tháng', 500000.00, '2025-01-01', '2025-02-01', GETDATE(), GETDATE(), 0),
(2, N'Gói Quý', 1350000.00, '2025-01-05', '2025-04-05', GETDATE(), GETDATE(), 0),
(3, N'Gói Năm', 5000000.00, '2025-01-10', '2026-01-10', GETDATE(), GETDATE(), 0),
(4, N'Gói Tháng', 500000.00, '2025-01-15', '2025-02-15', GETDATE(), GETDATE(), 0),
(5, N'Gói 6 Tháng', 2700000.00, '2025-02-01', '2025-08-01', GETDATE(), GETDATE(), 0),
(6, N'Gói Tháng', 500000.00, '2025-02-05', '2025-03-05', GETDATE(), GETDATE(), 0),
(7, N'Gói Quý', 1350000.00, '2025-02-10', '2025-05-10', GETDATE(), GETDATE(), 0),
(8, N'Gói Năm', 5000000.00, '2025-02-15', '2026-02-15', GETDATE(), GETDATE(), 0),
(9, N'Gói Tháng', 500000.00, '2025-03-01', '2025-04-01', GETDATE(), GETDATE(), 0),
(10, N'Gói 6 Tháng', 2700000.00, '2025-03-05', '2025-09-05', GETDATE(), GETDATE(), 0),
(11, N'Gói Quý', 1350000.00, '2025-03-10', '2025-06-10', GETDATE(), GETDATE(), 0),
(12, N'Gói Tháng', 500000.00, '2025-03-15', '2025-04-15', GETDATE(), GETDATE(), 0),
(13, N'Gói Năm', 5000000.00, '2025-04-01', '2026-04-01', GETDATE(), GETDATE(), 0),
(14, N'Gói Quý', 1350000.00, '2025-04-05', '2025-07-05', GETDATE(), GETDATE(), 0),
(15, N'Gói 6 Tháng', 2700000.00, '2025-04-10', '2025-10-10', GETDATE(), GETDATE(), 0),
(16, N'Gói Tháng', 500000.00, '2025-04-15', '2025-05-15', GETDATE(), GETDATE(), 0),
(17, N'Gói Quý', 1350000.00, '2025-05-01', '2025-08-01', GETDATE(), GETDATE(), 0),
(18, N'Gói Năm', 5000000.00, '2025-05-05', '2026-05-05', GETDATE(), GETDATE(), 0),
(19, N'Gói Tháng', 500000.00, '2025-05-10', '2025-06-10', GETDATE(), GETDATE(), 0),
(20, N'Gói 6 Tháng', 2700000.00, '2025-05-15', '2025-11-15', GETDATE(), GETDATE(), 0);

-- 6. INSERT INVOICES
INSERT INTO Invoices (MemberId, MembershipId, InvoiceDate, DueDate, TotalAmount, Status, Description, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, 1, '2025-01-01', '2025-01-08', 500000.00, 'Paid', N'Hóa đơn gói tháng - Nguyễn Thị Mai', GETDATE(), GETDATE(), 0),
(2, 2, '2025-01-05', '2025-01-12', 1350000.00, 'Paid', N'Hóa đơn gói quý - Trần Văn Nam', GETDATE(), GETDATE(), 0),
(3, 3, '2025-01-10', '2025-01-17', 5000000.00, 'Paid', N'Hóa đơn gói năm - Lê Thị Oanh', GETDATE(), GETDATE(), 0),
(4, 4, '2025-01-15', '2025-01-22', 500000.00, 'Paid', N'Hóa đơn gói tháng - Phạm Văn Phúc', GETDATE(), GETDATE(), 0),
(5, 5, '2025-02-01', '2025-02-08', 2700000.00, 'Paid', N'Hóa đơn gói 6 tháng - Hoàng Thị Quỳnh', GETDATE(), GETDATE(), 0),
(6, 6, '2025-02-05', '2025-02-12', 500000.00, 'Pending', N'Hóa đơn gói tháng - Vũ Văn Rồng', GETDATE(), GETDATE(), 0),
(7, 7, '2025-02-10', '2025-02-17', 1350000.00, 'Paid', N'Hóa đơn gói quý - Đỗ Thị Sương', GETDATE(), GETDATE(), 0),
(8, 8, '2025-02-15', '2025-02-22', 5000000.00, 'Paid', N'Hóa đơn gói năm - Bùi Văn Tài', GETDATE(), GETDATE(), 0),
(9, 9, '2025-03-01', '2025-03-08', 500000.00, 'Pending', N'Hóa đơn gói tháng - Ngô Thị Uyên', GETDATE(), GETDATE(), 0),
(10, 10, '2025-03-05', '2025-03-12', 2700000.00, 'Paid', N'Hóa đơn gói 6 tháng - Đinh Văn Vinh', GETDATE(), GETDATE(), 0),
(11, 11, '2025-03-10', '2025-03-17', 1350000.00, 'Paid', N'Hóa đơn gói quý - Đặng Thị Xuân', GETDATE(), GETDATE(), 0),
(12, 12, '2025-03-15', '2025-03-22', 500000.00, 'Pending', N'Hóa đơn gói tháng - Cao Văn Yên', GETDATE(), GETDATE(), 0),
(13, 13, '2025-04-01', '2025-04-08', 5000000.00, 'Paid', N'Hóa đơn gói năm - Lưu Thị Ánh', GETDATE(), GETDATE(), 0),
(14, 14, '2025-04-05', '2025-04-12', 1350000.00, 'Paid', N'Hóa đơn gói quý - Dương Văn Bảo', GETDATE(), GETDATE(), 0),
(15, 15, '2025-04-10', '2025-04-17', 2700000.00, 'Pending', N'Hóa đơn gói 6 tháng - Phan Thị Chi', GETDATE(), GETDATE(), 0),
(16, 16, '2025-04-15', '2025-04-22', 500000.00, 'Paid', N'Hóa đơn gói tháng - Võ Văn Đức', GETDATE(), GETDATE(), 0),
(17, 17, '2025-05-01', '2025-05-08', 1350000.00, 'Paid', N'Hóa đơn gói quý - Trương Thị Em', GETDATE(), GETDATE(), 0),
(18, 18, '2025-05-05', '2025-05-12', 5000000.00, 'Paid', N'Hóa đơn gói năm - Hồ Văn Phong', GETDATE(), GETDATE(), 0),
(19, 19, '2025-05-10', '2025-05-17', 500000.00, 'Pending', N'Hóa đơn gói tháng - Tô Thị Giang', GETDATE(), GETDATE(), 0),
(20, 20, '2025-05-15', '2025-05-22', 2700000.00, 'Paid', N'Hóa đơn gói 6 tháng - Lý Văn Hào', GETDATE(), GETDATE(), 0);

-- 7. INSERT PAYMENTS
INSERT INTO Payments (InvoiceId, MemberId, Amount, PaymentMethod, PaymentDate, TransactionId, Status, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, 1, 500000.00, 'Cash', '2025-01-01', NULL, 'Completed', GETDATE(), GETDATE(), 0),
(2, 2, 1350000.00, 'BankTransfer', '2025-01-05', 'BT20250105001', 'Completed', GETDATE(), GETDATE(), 0),
(3, 3, 5000000.00, 'Card', '2025-01-10', 'CARD20250110001', 'Completed', GETDATE(), GETDATE(), 0),
(4, 4, 500000.00, 'Cash', '2025-01-15', NULL, 'Completed', GETDATE(), GETDATE(), 0),
(5, 5, 2700000.00, 'BankTransfer', '2025-02-01', 'BT20250201001', 'Completed', GETDATE(), GETDATE(), 0),
(7, 7, 1350000.00, 'Card', '2025-02-10', 'CARD20250210001', 'Completed', GETDATE(), GETDATE(), 0),
(8, 8, 5000000.00, 'BankTransfer', '2025-02-15', 'BT20250215001', 'Completed', GETDATE(), GETDATE(), 0),
(10, 10, 2700000.00, 'Cash', '2025-03-05', NULL, 'Completed', GETDATE(), GETDATE(), 0),
(11, 11, 1350000.00, 'BankTransfer', '2025-03-10', 'BT20250310001', 'Completed', GETDATE(), GETDATE(), 0),
(13, 13, 5000000.00, 'Card', '2025-04-01', 'CARD20250401001', 'Completed', GETDATE(), GETDATE(), 0),
(14, 14, 1350000.00, 'Cash', '2025-04-05', NULL, 'Completed', GETDATE(), GETDATE(), 0),
(16, 16, 500000.00, 'BankTransfer', '2025-04-15', 'BT20250415001', 'Completed', GETDATE(), GETDATE(), 0),
(17, 17, 1350000.00, 'Card', '2025-05-01', 'CARD20250501001', 'Completed', GETDATE(), GETDATE(), 0),
(18, 18, 5000000.00, 'BankTransfer', '2025-05-05', 'BT20250505001', 'Completed', GETDATE(), GETDATE(), 0),
(20, 20, 2700000.00, 'Cash', '2025-05-15', NULL, 'Completed', GETDATE(), GETDATE(), 0);

-- 8. INSERT SCHEDULES
INSERT INTO Schedules (TrainerId, FacilityId, ClassName, StartTime, EndTime, MaxCapacity, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, 1, N'Gym Buổi Sáng', '2025-01-06 06:00:00', '2025-01-06 07:30:00', 20, GETDATE(), GETDATE(), 0),
(1, 1, N'Gym Buổi Tối', '2025-01-06 18:00:00', '2025-01-06 19:30:00', 20, GETDATE(), GETDATE(), 0),
(2, 2, N'Yoga Cơ Bản', '2025-01-07 07:00:00', '2025-01-07 08:00:00', 15, GETDATE(), GETDATE(), 0),
(2, 2, N'Yoga Nâng Cao', '2025-01-07 19:00:00', '2025-01-07 20:00:00', 15, GETDATE(), GETDATE(), 0),
(3, 3, N'Cardio Cường Độ Cao', '2025-01-08 06:30:00', '2025-01-08 07:30:00', 25, GETDATE(), GETDATE(), 0),
(3, 3, N'Cardio Buổi Chiều', '2025-01-08 17:00:00', '2025-01-08 18:00:00', 25, GETDATE(), GETDATE(), 0),
(4, 4, N'Aerobic Sáng', '2025-01-09 06:00:00', '2025-01-09 07:00:00', 30, GETDATE(), GETDATE(), 0),
(4, 4, N'Aerobic Tối', '2025-01-09 18:30:00', '2025-01-09 19:30:00', 30, GETDATE(), GETDATE(), 0),
(5, 5, N'Boxing Cơ Bản', '2025-01-10 07:00:00', '2025-01-10 08:30:00', 12, GETDATE(), GETDATE(), 0),
(5, 5, N'Boxing Nâng Cao', '2025-01-10 19:00:00', '2025-01-10 20:30:00', 12, GETDATE(), GETDATE(), 0),
(1, 6, N'Tập Tạ Tự Do', '2025-01-13 08:00:00', '2025-01-13 09:30:00', 15, GETDATE(), GETDATE(), 0),
(2, 8, N'Pilates Buổi Sáng', '2025-01-14 07:30:00', '2025-01-14 08:30:00', 12, GETDATE(), GETDATE(), 0),
(3, 9, N'Spinning Buổi Sáng', '2025-01-15 06:00:00', '2025-01-15 07:00:00', 20, GETDATE(), GETDATE(), 0),
(3, 9, N'Spinning Buổi Tối', '2025-01-15 18:00:00', '2025-01-15 19:00:00', 20, GETDATE(), GETDATE(), 0),
(4, 10, N'Dance Fitness', '2025-01-16 19:00:00', '2025-01-16 20:00:00', 25, GETDATE(), GETDATE(), 0),
(1, 1, N'Gym Thứ 7', '2025-01-17 08:00:00', '2025-01-17 10:00:00', 25, GETDATE(), GETDATE(), 0),
(2, 2, N'Yoga Cuối Tuần', '2025-01-18 09:00:00', '2025-01-18 10:30:00', 20, GETDATE(), GETDATE(), 0),
(3, 3, N'Cardio Chủ Nhật', '2025-01-18 10:00:00', '2025-01-18 11:00:00', 30, GETDATE(), GETDATE(), 0),
(4, 4, N'Zumba Cuối Tuần', '2025-01-18 17:00:00', '2025-01-18 18:00:00', 35, GETDATE(), GETDATE(), 0),
(5, 5, N'Boxing Chủ Nhật', '2025-01-18 08:00:00', '2025-01-18 09:30:00', 15, GETDATE(), GETDATE(), 0);

-- 9. INSERT SESSIONS
INSERT INTO Sessions (ScheduleId, MemberId, RegistrationDate, Status, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, 1, '2025-01-02', 'Attended', GETDATE(), GETDATE(), 0),
(1, 2, '2025-01-02', 'Attended', GETDATE(), GETDATE(), 0),
(1, 3, '2025-01-02', 'Registered', GETDATE(), GETDATE(), 0),
(3, 4, '2025-01-03', 'Attended', GETDATE(), GETDATE(), 0),
(3, 5, '2025-01-03', 'Attended', GETDATE(), GETDATE(), 0),
(5, 6, '2025-01-04', 'Registered', GETDATE(), GETDATE(), 0),
(5, 7, '2025-01-04', 'Attended', GETDATE(), GETDATE(), 0),
(7, 8, '2025-01-05', 'Attended', GETDATE(), GETDATE(), 0),
(7, 9, '2025-01-05', 'Cancelled', GETDATE(), GETDATE(), 0),
(9, 10, '2025-01-06', 'Attended', GETDATE(), GETDATE(), 0),
(2, 11, '2025-01-03', 'Attended', GETDATE(), GETDATE(), 0),
(2, 12, '2025-01-03', 'Registered', GETDATE(), GETDATE(), 0),
(4, 13, '2025-01-04', 'Attended', GETDATE(), GETDATE(), 0),
(6, 14, '2025-01-05', 'Attended', GETDATE(), GETDATE(), 0),
(8, 15, '2025-01-06', 'Registered', GETDATE(), GETDATE(), 0),
(10, 16, '2025-01-07', 'Attended', GETDATE(), GETDATE(), 0),
(11, 17, '2025-01-08', 'Attended', GETDATE(), GETDATE(), 0),
(12, 18, '2025-01-09', 'Registered', GETDATE(), GETDATE(), 0),
(13, 19, '2025-01-10', 'Attended', GETDATE(), GETDATE(), 0),
(14, 20, '2025-01-11', 'Attended', GETDATE(), GETDATE(), 0),
(15, 1, '2025-01-12', 'Registered', GETDATE(), GETDATE(), 0),
(16, 2, '2025-01-13', 'Attended', GETDATE(), GETDATE(), 0),
(17, 3, '2025-01-14', 'Attended', GETDATE(), GETDATE(), 0),
(18, 4, '2025-01-15', 'Cancelled', GETDATE(), GETDATE(), 0),
(19, 5, '2025-01-16', 'Attended', GETDATE(), GETDATE(), 0),
(20, 6, '2025-01-17', 'Attended', GETDATE(), GETDATE(), 0);

-- 10. INSERT CHECKINS
INSERT INTO Checkins (MemberId, CheckinTime, CheckoutTime, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(1, '2025-01-06 06:00:00', '2025-01-06 07:45:00', GETDATE(), GETDATE(), 0),
(2, '2025-01-06 06:05:00', '2025-01-06 07:50:00', GETDATE(), GETDATE(), 0),
(3, '2025-01-06 06:10:00', NULL, GETDATE(), GETDATE(), 0),
(4, '2025-01-07 07:00:00', '2025-01-07 08:15:00', GETDATE(), GETDATE(), 0),
(5, '2025-01-07 07:05:00', '2025-01-07 08:20:00', GETDATE(), GETDATE(), 0),
(6, '2025-01-08 06:30:00', '2025-01-08 07:45:00', GETDATE(), GETDATE(), 0),
(7, '2025-01-08 06:35:00', '2025-01-08 07:50:00', GETDATE(), GETDATE(), 0),
(8, '2025-01-09 06:00:00', '2025-01-09 07:15:00', GETDATE(), GETDATE(), 0),
(10, '2025-01-10 07:00:00', '2025-01-10 08:45:00', GETDATE(), GETDATE(), 0),
(11, '2025-01-06 18:00:00', '2025-01-06 19:45:00', GETDATE(), GETDATE(), 0),
(12, '2025-01-06 18:05:00', NULL, GETDATE(), GETDATE(), 0),
(13, '2025-01-07 19:00:00', '2025-01-07 20:15:00', GETDATE(), GETDATE(), 0),
(14, '2025-01-08 17:00:00', '2025-01-08 18:15:00', GETDATE(), GETDATE(), 0),
(15, '2025-01-09 18:30:00', NULL, GETDATE(), GETDATE(), 0),
(16, '2025-01-10 19:00:00', '2025-01-10 20:45:00', GETDATE(), GETDATE(), 0),
(17, '2025-01-13 08:00:00', '2025-01-13 09:45:00', GETDATE(), GETDATE(), 0),
(18, '2025-01-14 07:30:00', NULL, GETDATE(), GETDATE(), 0),
(19, '2025-01-15 06:00:00', '2025-01-15 07:15:00', GETDATE(), GETDATE(), 0),
(20, '2025-01-16 19:00:00', '2025-01-16 20:15:00', GETDATE(), GETDATE(), 0);

-- 11. INSERT MEMBER SCHEDULE PREFERENCES
INSERT INTO MemberSchedulePreferences (MemberId, DayOfWeek, StartTime, EndTime, IsActive, CreatedAt, UpdatedAt)
VALUES 
(1, 1, '06:00:00', '08:00:00', 1, GETDATE(), GETDATE()),
(2, 1, '18:00:00', '20:00:00', 1, GETDATE(), GETDATE()),
(3, 2, '07:00:00', '09:00:00', 1, GETDATE(), GETDATE()),
(4, 3, '06:00:00', '08:00:00', 1, GETDATE(), GETDATE()),
(5, 4, '19:00:00', '21:00:00', 1, GETDATE(), GETDATE()),
(6, 5, '07:00:00', '09:00:00', 1, GETDATE(), GETDATE()),
(7, 6, '08:00:00', '10:00:00', 1, GETDATE(), GETDATE()),
(8, 0, '09:00:00', '11:00:00', 1, GETDATE(), GETDATE()),
(9, 1, '17:00:00', '19:00:00', 1, GETDATE(), GETDATE()),
(10, 2, '18:00:00', '20:00:00', 1, GETDATE(), GETDATE());

-- 12. INSERT AUDIT LOGS (Sample data for testing)
INSERT INTO AuditLogs (TableName, RecordId, Action, UserId, Username, OldValues, NewValues, ChangedAt, IpAddress, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
('Users', 1, 'INSERT', 1, 'admin', NULL, '{"Username":"admin","Role":"Admin"}', GETDATE(), '127.0.0.1', GETDATE(), GETDATE(), 0),
('Members', 1, 'INSERT', 1, 'admin', NULL, '{"FullName":"Nguyễn Thị Mai","QRCode":"M000001"}', GETDATE(), '127.0.0.1', GETDATE(), GETDATE(), 0),
('Memberships', 1, 'INSERT', 1, 'admin', NULL, '{"MemberId":1,"PackageName":"Gói Tháng","Price":500000}', GETDATE(), '127.0.0.1', GETDATE(), GETDATE(), 0),
('Invoices', 1, 'INSERT', 1, 'admin', NULL, '{"InvoiceId":1,"TotalAmount":500000,"Status":"Paid"}', GETDATE(), '127.0.0.1', GETDATE(), GETDATE(), 0),
('Payments', 1, 'INSERT', 1, 'admin', NULL, '{"PaymentId":1,"Amount":500000,"PaymentMethod":"Cash"}', GETDATE(), '127.0.0.1', GETDATE(), GETDATE(), 0);

PRINT 'Seed data inserted successfully';
PRINT '- 26 Users (1 Admin, 5 Trainers, 20 Members)';
PRINT '- 5 Trainers';
PRINT '- 20 Members';
PRINT '- 10 Facilities';
PRINT '- 20 Memberships';
PRINT '- 20 Invoices';
PRINT '- 15 Payments';
PRINT '- 20 Schedules';
PRINT '- 26 Sessions';
PRINT '- 19 Checkins';
PRINT '- 10 Member Schedule Preferences';
PRINT '- 5 Audit Logs';
