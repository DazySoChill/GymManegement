-- =============================================
-- FILE: 00_CREATE_DATABASE.sql
-- PURPOSE: Database initialization and creation
-- DESCRIPTION: Drops existing GymDb (if exists) and creates a new database
--              with Vietnamese_CI_AS collation for proper Vietnamese text support
-- =============================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'GymDb')
BEGIN
    ALTER DATABASE GymDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GymDb;
    PRINT 'Dropped existing GymDb database';
END
GO

CREATE DATABASE GymDb COLLATE Vietnamese_CI_AS;
GO

PRINT 'Created GymDb database with Vietnamese_CI_AS collation';
GO

USE GymDb;
GO
