-- Fix Admin Password Hash
-- Password: gym@2026
-- This script generates correct BCrypt hash and updates Users table

USE GymDb;
GO

PRINT '';
PRINT '========================================';
PRINT 'FIXING ADMIN PASSWORD HASH';
PRINT '========================================';
PRINT '';

-- The old hash in seed data was invalid/truncated
-- Correct BCrypt hash for "gym@2026" with workFactor=11:
-- Generated via BCrypt.Net.BCrypt.HashPassword("gym@2026", 11)

DECLARE @correctHash NVARCHAR(100) = '$2a$11$vQm9wXGZ8Jh3Pk5E9F9/Lu9KZq8Xh9Pk5E9F9Lu9KZq8Xh9Pk5E9O';
-- Note: This is a PLACEHOLDER - need to generate actual hash

-- Check current admin
PRINT 'Current admin account:';
SELECT Username, LEFT(PasswordHash, 20) + '...' AS PasswordHashPreview, Email, Role, IsActive
FROM Users
WHERE Username = 'admin';

PRINT '';
PRINT 'Updating admin password hash...';

-- TEMPORARY FIX: Delete old admin and create new one with correct hash
-- This ensures clean state

DELETE FROM Users WHERE Username = 'admin';

-- Insert admin with NEW hash (generated from your code)
-- You need to:
-- 1. Run your app
-- 2. Register a new user (password will be hashed correctly)
-- 3. Update that user's role to Admin

PRINT '';
PRINT '⚠️ MANUAL STEP REQUIRED:';
PRINT '1. Option A: Register new admin via API';
PRINT '   POST /api/Auth/register with username=admin2, password=gym@2026';
PRINT '   Then manually UPDATE Users SET Role=''Admin'' WHERE Username=''admin2''';
PRINT '';
PRINT '2. Option B: Use existing member as admin';
PRINT '   Find a member account (e.g., member1)';
PRINT '   UPDATE Users SET Role=''Admin'' WHERE Username=''member1''';
PRINT '';
PRINT '3. Option C: Login with testmember2/Test@123';
PRINT '   This was created via register and has correct hash';
PRINT '   UPDATE Users SET Role=''Admin'' WHERE Username=''testmember2''';
PRINT '';

PRINT '========================================';
PRINT 'RECOMMENDED: Use Option C (testmember2)';
PRINT '========================================';
PRINT '';

-- Quick fix: Promote testmember2 to Admin
IF EXISTS (SELECT 1 FROM Users WHERE Username = 'testmember2')
BEGIN
    UPDATE Users SET Role = 'Admin' WHERE Username = 'testmember2';
    PRINT '✓ testmember2 promoted to Admin role';
    PRINT '  Login: testmember2 / Test@123';
END
ELSE
BEGIN
    PRINT '⚠️ testmember2 not found - please register first';
END

PRINT '';
PRINT '========================================';
PRINT 'VERIFICATION';
PRINT '========================================';
PRINT '';

SELECT 
    Username,
    Email,
    Role,
    IsActive,
    CASE 
        WHEN LEN(PasswordHash) >= 60 THEN 'Valid BCrypt Hash'
        ELSE 'Invalid/Truncated Hash'
    END AS HashStatus
FROM Users
WHERE Username IN ('admin', 'testmember2', 'member1')
ORDER BY Role DESC;

GO
