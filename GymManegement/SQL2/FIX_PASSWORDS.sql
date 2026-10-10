-- ============================================================
-- FIX PASSWORD HASHES
-- Update all users to use correct BCrypt hash for 'password'
-- ============================================================

USE GymDb;
GO

PRINT 'Fixing password hashes for all users...';

-- Correct BCrypt hash for password 'password' with workFactor 11
DECLARE @CorrectHash NVARCHAR(255) = '$2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq';

UPDATE Users
SET PasswordHash = @CorrectHash,
    UpdatedAt = GETDATE()
WHERE IsDeleted = 0;

PRINT 'Password hashes updated for all active users';
PRINT '';
PRINT 'Test accounts (all use password: ''password''):';
PRINT '  admin / password';
PRINT '  trainer1 / password';
PRINT '  trainer2 / password';
PRINT '  trainer3 / password';
PRINT '  trainer4 / password';
PRINT '  trainer5 / password';
PRINT '  member01 / password';
PRINT '  member02 / password';
PRINT '  ... (all members use password)';
PRINT '';
PRINT 'Password fix completed!';
GO
