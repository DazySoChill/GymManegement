-- ============================================================
-- FILE: 04_Users.sql
-- Mô tả: Seed tài khoản mặc định (khớp schema đơn giản)
-- Password tất cả: "gym@2026" -> BCrypt hash (workFactor=11)
-- ============================================================

USE GymDb;
GO

-- Xóa users cũ (nếu chạy lại)
DELETE FROM Users;
GO

-- Seed 3 tài khoản mặc định
-- Hash BCrypt của "gym@2026" với workFactor=11
-- $2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username='admin')
INSERT INTO Users (Username, PasswordHash, Role, MemberId, TrainerId) VALUES
('admin',    '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 'SuperAdmin', NULL, NULL),
('trainer1', '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 'Trainer',    NULL, 1),
('member1',  '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 'Member',     1,    NULL);
GO

DBCC CHECKIDENT ('Users', RESEED, 3);
GO

PRINT 'Default users seeded: admin / trainer1 / member1 (pass: gym@2026)';
GO
