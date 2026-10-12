-- ============================================================
-- Migration: Fix missing Trainer/Member records for existing users
-- Run once against the database after deploying the code changes
-- ============================================================

PRINT 'Starting migration: fix-missing-trainer-member-records';

-- Step 1: Create Trainer records for existing Trainer-role users who lack one
INSERT INTO Trainers (FullName, Email, Phone, Specialization, CreatedAt, UpdatedAt, IsDeleted)
SELECT
    u.FullName,
    u.Email,
    '' AS Phone,
    'General' AS Specialization,
    GETDATE() AS CreatedAt,
    GETDATE() AS UpdatedAt,
    0 AS IsDeleted
FROM Users u
WHERE u.Role = 'Trainer'
  AND u.IsDeleted = 0
  AND NOT EXISTS (
      SELECT 1 FROM Trainers t
      WHERE t.Email = u.Email AND t.IsDeleted = 0
  );

PRINT CONCAT('Trainer records inserted: ', @@ROWCOUNT);

-- Step 2: Create Member records with temporary QRCodes
INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode, CreatedAt, UpdatedAt, IsDeleted)
SELECT
    u.FullName,
    u.Email,
    NULL AS Phone,
    NULL AS DateOfBirth,
    'TEMP_' + CAST(u.UserId AS VARCHAR) AS QRCode, -- Temporary unique QRCode
    GETDATE() AS CreatedAt,
    GETDATE() AS UpdatedAt,
    0 AS IsDeleted
FROM Users u
WHERE u.Role = 'Member'
  AND u.IsDeleted = 0
  AND NOT EXISTS (
      SELECT 1 FROM Members m
      WHERE m.Email = u.Email AND m.IsDeleted = 0
  );

DECLARE @MemberInsertCount INT = @@ROWCOUNT;
PRINT CONCAT('Member records inserted: ', @MemberInsertCount);

-- Step 3: Update QRCodes using the assigned MemberIds (concurrency-safe)
UPDATE Members
SET QRCode = 'M' + RIGHT('000000' + CAST(MemberId AS VARCHAR), 6),
    UpdatedAt = GETDATE()
WHERE QRCode LIKE 'TEMP_%';

PRINT CONCAT('QRCodes updated: ', @@ROWCOUNT);

-- Step 4: Verification query - shows current sync status
SELECT
    u.UserId,
    u.FullName,
    u.Email,
    u.Role,
    t.TrainerId,
    m.MemberId,
    m.QRCode,
    CASE
        WHEN u.Role = 'Trainer' AND t.TrainerId IS NULL THEN 'MISSING TRAINER RECORD'
        WHEN u.Role = 'Member'  AND m.MemberId IS NULL THEN 'MISSING MEMBER RECORD'
        WHEN u.Role = 'Member'  AND m.QRCode LIKE 'TEMP_%' THEN 'QRCODE NOT UPDATED'
        ELSE 'OK'
    END AS SyncStatus
FROM Users u
LEFT JOIN Trainers t ON t.Email = u.Email AND t.IsDeleted = 0
LEFT JOIN Members  m ON m.Email = u.Email AND m.IsDeleted = 0
WHERE u.IsDeleted = 0
ORDER BY u.Role, u.UserId;

PRINT 'Migration complete.';
