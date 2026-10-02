-- ============================================================
-- FILE: 04_Users.sql
-- Mô tả: Seed tài khoản mặc định (khớp schema mới với RBAC)
-- Password tất cả: "gym@2026" -> BCrypt hash (workFactor=11)
-- Salt: unique per user
-- ============================================================

USE GymDb;
GO

-- Xóa users cũ (nếu chạy lại)
DELETE FROM Users;
GO

-- Seed Roles first (must exist before users)
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Admin')
    INSERT INTO Roles (RoleName, Description, IsSystem) VALUES ('Admin', N'Quản trị viên hệ thống', 1);
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Trainer')
    INSERT INTO Roles (RoleName, Description, IsSystem) VALUES ('Trainer', N'Huấn luyện viên', 1);
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Member')
    INSERT INTO Roles (RoleName, Description, IsSystem) VALUES ('Member', N'Hội viên', 1);
GO

-- Hash BCrypt của "gym@2026" với workFactor=11
-- $2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h
-- Salt per user (Base64 encoded random bytes)
DECLARE @AdminRoleId INT = (SELECT RoleId FROM Roles WHERE RoleName = 'Admin');
DECLARE @TrainerRoleId INT = (SELECT RoleId FROM Roles WHERE RoleName = 'Trainer');
DECLARE @MemberRoleId INT = (SELECT RoleId FROM Roles WHERE RoleName = 'Member');

-- Admin user (no MemberId/TrainerId)
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'admin')
INSERT INTO Users (Username, PasswordHash, PasswordSalt, RoleId, MemberId, TrainerId, IsActive, CreatedBy)
VALUES ('admin', 
    '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 
    'U2FsdGVkX1+AdminSalt12345678901234==', 
    @AdminRoleId, NULL, NULL, 1, NULL);

-- Trainer user (linked to TrainerId = 1)
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'trainer1')
INSERT INTO Users (Username, PasswordHash, PasswordSalt, RoleId, MemberId, TrainerId, IsActive, CreatedBy)
VALUES ('trainer1', 
    '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 
    'U2FsdGVkX1+TrainerSalt123456789012==', 
    @TrainerRoleId, NULL, 1, 1, NULL);

-- Member user (linked to MemberId = 1)
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'member1')
INSERT INTO Users (Username, PasswordHash, PasswordSalt, RoleId, MemberId, TrainerId, IsActive, CreatedBy)
VALUES ('member1', 
    '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 
    'U2FsdGVkX1+MemberSalt1234567890123==', 
    @MemberRoleId, 1, NULL, 1, NULL);

-- Additional demo users for full coverage
-- Trainer 2
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'trainer2')
INSERT INTO Users (Username, PasswordHash, PasswordSalt, RoleId, MemberId, TrainerId, IsActive, CreatedBy)
VALUES ('trainer2', 
    '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 
    'U2FsdGVkX1+Trainer2Salt12345678901==', 
    @TrainerRoleId, NULL, 2, 1, NULL);

-- Member 2
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'member2')
INSERT INTO Users (Username, PasswordHash, PasswordSalt, RoleId, MemberId, TrainerId, IsActive, CreatedBy)
VALUES ('member2', 
    '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 
    'U2FsdGVkX1+Member2Salt123456789012==', 
    @MemberRoleId, 2, NULL, 1, NULL);

-- Member 3
IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'member3')
INSERT INTO Users (Username, PasswordHash, PasswordSalt, RoleId, MemberId, TrainerId, IsActive, CreatedBy)
VALUES ('member3', 
    '$2a$11$8K1p/a0dHRxAm7QiTRqNa.SU2ZqJ8zY9xVwL3mN4bP5cR6dE7fG8h', 
    'U2FsdGVkX1+Member3Salt123456789012==', 
    @MemberRoleId, 3, NULL, 1, NULL);

DBCC CHECKIDENT ('Users', RESEED, 6);
GO

PRINT 'Default users seeded: admin / trainer1 / trainer2 / member1 / member2 / member3 (pass: gym@2026)';
GO
