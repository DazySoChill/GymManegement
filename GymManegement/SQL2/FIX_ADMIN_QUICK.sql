-- QUICK FIX: Promote testmember2 to Admin
-- testmember2 was registered via API so it has correct BCrypt hash

USE GymDb;
GO

PRINT 'Promoting testmember2 to Admin...';

UPDATE Users 
SET Role = 'Admin' 
WHERE Username = 'testmember2' AND IsDeleted = 0;

PRINT '✓ Done!';
PRINT '';
PRINT 'You can now login as Admin:';
PRINT '  Username: testmember2';
PRINT '  Password: Test@123';
PRINT '  Role: Admin';
