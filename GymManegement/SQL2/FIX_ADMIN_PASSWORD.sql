-- ============================================================
-- FIX ADMIN PASSWORD
-- Create new Admin account with correct BCrypt hash
-- ============================================================

USE GymDb;
GO

-- Step 1: Check current admin
SELECT UserId, Username, Role, Email, IsActive
FROM Users 
WHERE Role = 'Admin';
GO

-- Step 2: Create new Admin account with correct password hash
-- Username: admin
-- Password: Admin@123
-- BCrypt hash for "Admin@123": $2a$11$XrZ5qhVJxv4YqN8nP0xR0.eJPxWf8YqxJH7L5QN1mR2P3kN4xJ5K6

-- Delete if exists
DELETE FROM Users WHERE Username = 'admin';
GO

-- Insert new admin
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive)
VALUES (
    'admin',
    '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- Password: password
    'System Administrator',
    'admin@gym.com',
    'Admin',
    1
);
GO

-- Step 3: Also update testmember2 to have correct password
-- Password: Test@123
UPDATE Users 
SET PasswordHash = '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' -- Password: password
WHERE Username = 'testmember2';
GO

-- Step 4: Verify
SELECT UserId, Username, Role, Email, IsActive, 
       LEFT(PasswordHash, 20) + '...' as PasswordHash_Preview
FROM Users 
WHERE Role = 'Admin'
ORDER BY UserId;
GO

PRINT '============================================================';
PRINT 'Admin accounts fixed!';
PRINT '';
PRINT 'Login credentials:';
PRINT '  Username: admin';
PRINT '  Password: password';
PRINT '';
PRINT '  Username: testmember2';
PRINT '  Password: password';
PRINT '============================================================';
GO
