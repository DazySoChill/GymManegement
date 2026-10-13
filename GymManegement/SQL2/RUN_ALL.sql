-- =============================================
-- FILE: RUN_ALL.sql
-- PURPOSE: Master execution script to run all SQL setup files in order
-- DESCRIPTION: This script uses SQLCMD mode to execute all database setup
--              files in the correct sequence. Must be run in SSMS with
--              SQLCMD Mode enabled (Query → SQLCMD Mode)
-- =============================================
-- 
-- HOW TO USE:
-- 1. Open this file in SQL Server Management Studio (SSMS)
-- 2. Enable SQLCMD Mode: Query menu → SQLCMD Mode (check it)
-- 3. Press F5 or click Execute
-- 4. All files will run in sequence automatically
--
-- EXECUTION ORDER:
-- 00 → Database Creation
-- 01 → Tables & Constraints
-- 02-13 → Stored Procedures (by domain)
-- 14 → Seed Data
--
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'GYM MANAGEMENT SYSTEM - COMPLETE SETUP';
PRINT 'Starting database initialization...';
PRINT '=============================================';
PRINT '';

:r 00_CREATE_DATABASE.sql
:r 01_CREATE_TABLES.sql
:r 14_SEED_DATA.sql

PRINT '';
PRINT '=============================================';
PRINT 'DATABASE SETUP COMPLETE!';
PRINT '=============================================';
PRINT '';
PRINT 'Database Summary:';
PRINT '  Database: GymDb (Vietnamese_CI_AS collation)';
PRINT '  Tables: 12 total';
PRINT '  Seed Data: Populated with sample records';
PRINT '';
PRINT 'NOTE: Stored procedures are available in COMPLETE_GYM_MANAGEMENT_SYSTEM.sql';
PRINT '';
PRINT 'Test Credentials (password: password):';
PRINT '  Admin:    admin / password';
PRINT '  Trainer:  trainer1 / password';
PRINT '  Member:   member01 / password';
PRINT '';
PRINT 'Next Steps:';
PRINT '  1. Update appsettings.json connection string';
PRINT '  2. Run dotnet build';
PRINT '  3. Test login with admin/password';
PRINT '';
