-- ============================================================
-- RUN_COMPLETE_FIX.sql
-- Master script to run complete database fix
-- ============================================================

USE GymDb;
GO

PRINT '========================================';
PRINT '🚀 Starting Complete Database Fix...';
PRINT '========================================';
GO

PRINT '';
PRINT '========================================';
PRINT 'Step 1: Applying Schema Fixes...';
PRINT '========================================';
GO

-- Run COMPLETE_SCHEMA_FIX.sql
:r COMPLETE_SCHEMA_FIX.sql

GO

PRINT '';
PRINT '========================================';
PRINT 'Step 2: Seeding Data...';
PRINT '========================================';
GO

-- Run COMPLETE_SEED_DATA.sql
:r COMPLETE_SEED_DATA.sql

GO

PRINT '';
PRINT '========================================';
PRINT '✅ COMPLETE DATABASE FIX FINISHED!';
PRINT '========================================';
PRINT '';
PRINT 'Database GymDb is now ready to use!';
PRINT '';
PRINT 'Test Accounts:';
PRINT '  - SuperAdmin: gymadmin / Gym@2026';
PRINT '  - Trainer: trainer1 / Trainer@123';
PRINT '  - Member: member1 / Member@123';
PRINT '';
PRINT '========================================';
GO
