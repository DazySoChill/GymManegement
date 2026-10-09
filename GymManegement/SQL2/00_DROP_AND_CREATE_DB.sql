-- ============================================================
-- FILE: 00_DROP_AND_CREATE_DB.sql
-- MÔ TẢ: Drop và tạo database GymDb mới
-- CẢNH BÁO: Script này sẽ XÓA database hiện có!
-- ============================================================

USE master;
GO

-- Đóng tất cả connections đến GymDb
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'GymDb')
BEGIN
    ALTER DATABASE GymDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GymDb;
    PRINT 'Dropped existing GymDb database';
END
GO

-- Tạo database mới
CREATE DATABASE GymDb;
GO

PRINT 'Created new GymDb database';
GO

USE GymDb;
GO

PRINT 'Ready to run 01_SCHEMA_SIMPLIFIED.sql';
GO
