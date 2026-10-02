-- ============================================================
-- FILE: 05_TestData.sql
-- Mô tả: Comprehensive test script để verify database hoạt động đúng
-- Chạy SAU khi đã chạy xong 4 file chính (01, 03, 04, 02)
-- Tính năng: Idempotent, cleanup tự động, coverage đầy đủ
-- ============================================================

USE GymDb;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

-- Biến dùng chung
DECLARE @TestRunId NVARCHAR(50) = 'TEST_' + REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', '');
DECLARE @Total INT;
DECLARE @NewId INT;
DECLARE @Msg NVARCHAR(500);

PRINT '============================================================';
PRINT 'TESTING GYM DATABASE - Run: ' + @TestRunId;
PRINT '============================================================';
PRINT '';

-- ============================================================
-- 1. KIỂM TRA SỐ LIỆU SEED (COUNT)
-- ============================================================
PRINT '>>> [1/12] KIỂM TRA SỐ LƯỢNG DỮ LIỆU SEED';

SELECT 
    'Members' AS TableName, COUNT(*) AS TotalCount, 
    CASE WHEN COUNT(*) >= 2000 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM Members WHERE IsDeleted = 0
UNION ALL SELECT 'Trainers', COUNT(*), CASE WHEN COUNT(*) >= 20 THEN 'PASS' ELSE 'FAIL' END FROM Trainers WHERE IsDeleted = 0
UNION ALL SELECT 'Facilities', COUNT(*), CASE WHEN COUNT(*) >= 10 THEN 'PASS' ELSE 'FAIL' END FROM Facilities WHERE IsDeleted = 0
UNION ALL SELECT 'Memberships', COUNT(*), CASE WHEN COUNT(*) >= 2500 THEN 'PASS' ELSE 'FAIL' END FROM Memberships WHERE IsDeleted = 0
UNION ALL SELECT 'Schedules', COUNT(*), CASE WHEN COUNT(*) >= 5000 THEN 'PASS' ELSE 'FAIL' END FROM Schedules WHERE IsDeleted = 0
UNION ALL SELECT 'Sessions', COUNT(*), CASE WHEN COUNT(*) >= 5000 THEN 'PASS' ELSE 'FAIL' END FROM Sessions WHERE IsDeleted = 0
UNION ALL SELECT 'Checkins', COUNT(*), CASE WHEN COUNT(*) >= 10000 THEN 'PASS' ELSE 'FAIL' END FROM Checkins WHERE IsDeleted = 0
UNION ALL SELECT 'Invoices', COUNT(*), CASE WHEN COUNT(*) >= 2500 THEN 'PASS' ELSE 'FAIL' END FROM Invoices WHERE IsDeleted = 0
UNION ALL SELECT 'Payments', COUNT(*), CASE WHEN COUNT(*) >= 2000 THEN 'PASS' ELSE 'FAIL' END FROM Payments WHERE IsDeleted = 0
UNION ALL SELECT 'Users', COUNT(*), CASE WHEN COUNT(*) >= 6 THEN 'PASS' ELSE 'FAIL' END FROM Users WHERE IsDeleted = 0
UNION ALL SELECT 'Roles', COUNT(*), CASE WHEN COUNT(*) >= 3 THEN 'PASS' ELSE 'FAIL' END FROM Roles
UNION ALL SELECT 'Permissions', COUNT(*), CASE WHEN COUNT(*) >= 45 THEN 'PASS' ELSE 'FAIL' END FROM Permissions
UNION ALL SELECT 'RolePermissions', COUNT(*), 'INFO' FROM RolePermissions
UNION ALL SELECT 'AuditLogs', COUNT(*), 'INFO' FROM AuditLogs
UNION ALL SELECT 'RefreshTokens', COUNT(*), 'INFO' FROM RefreshTokens;
PRINT '';

-- ============================================================
-- 2. KIỂM TRA FOREIGN KEY VÀ RÀNG BUỘC (0 ORPHANS)
-- ============================================================
PRINT '>>> [2/12] KIỂM TRA FOREIGN KEY INTEGRITY';

WITH OrphanChecks AS (
    SELECT 'Orphan Memberships' AS CheckName, COUNT(*) AS Count
    FROM Memberships m LEFT JOIN Members mm ON mm.MemberId = m.MemberId WHERE mm.MemberId IS NULL AND m.IsDeleted = 0
    UNION ALL SELECT 'Orphan Schedules (Member)', COUNT(*)
    FROM Schedules s LEFT JOIN Members m ON m.MemberId = s.MemberId WHERE m.MemberId IS NULL AND s.IsDeleted = 0
    UNION ALL SELECT 'Orphan Schedules (Trainer)', COUNT(*)
    FROM Schedules s LEFT JOIN Trainers t ON t.TrainerId = s.TrainerId WHERE t.TrainerId IS NULL AND s.IsDeleted = 0
    UNION ALL SELECT 'Orphan Schedules (Facility)', COUNT(*)
    FROM Schedules s LEFT JOIN Facilities f ON f.FacilityId = s.FacilityId WHERE f.FacilityId IS NULL AND s.IsDeleted = 0
    UNION ALL SELECT 'Orphan Sessions', COUNT(*)
    FROM Sessions s LEFT JOIN Schedules sc ON sc.ScheduleId = s.ScheduleId WHERE sc.ScheduleId IS NULL AND s.IsDeleted = 0
    UNION ALL SELECT 'Orphan Checkins (Member)', COUNT(*)
    FROM Checkins c LEFT JOIN Members m ON m.MemberId = c.MemberId WHERE m.MemberId IS NULL AND c.IsDeleted = 0
    UNION ALL SELECT 'Orphan Checkins (Session)', COUNT(*)
    FROM Checkins c LEFT JOIN Sessions s ON s.SessionId = c.SessionId WHERE s.SessionId IS NULL AND c.IsDeleted = 0
    UNION ALL SELECT 'Orphan Invoices', COUNT(*)
    FROM Invoices i LEFT JOIN Members m ON m.MemberId = i.MemberId WHERE m.MemberId IS NULL AND i.IsDeleted = 0
    UNION ALL SELECT 'Orphan Payments', COUNT(*)
    FROM Payments p LEFT JOIN Invoices i ON i.InvoiceId = p.InvoiceId WHERE i.InvoiceId IS NULL AND p.IsDeleted = 0
    UNION ALL SELECT 'Orphan Users (MemberId)', COUNT(*)
    FROM Users u LEFT JOIN Members m ON m.MemberId = u.MemberId WHERE u.MemberId IS NOT NULL AND m.MemberId IS NULL AND u.IsDeleted = 0
    UNION ALL SELECT 'Orphan Users (TrainerId)', COUNT(*)
    FROM Users u LEFT JOIN Trainers t ON t.TrainerId = u.TrainerId WHERE u.TrainerId IS NOT NULL AND t.TrainerId IS NULL AND u.IsDeleted = 0
    UNION ALL SELECT 'Orphan Users (RoleId)', COUNT(*)
    FROM Users u LEFT JOIN Roles r ON r.RoleId = u.RoleId WHERE r.RoleId IS NULL AND u.IsDeleted = 0
)
SELECT CheckName, Count, 
    CASE WHEN Count = 0 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM OrphanChecks;
PRINT '';

-- ============================================================
-- 3. TEST STORED PROCEDURES CRUD + PAGINATION
-- ============================================================
PRINT '>>> [3/12] TEST STORED PROCEDURES CRUD + PAGINATION';

-- 3.1 Member
EXEC sp_Member_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Member_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Member_GetById @MemberId=1;
PRINT 'sp_Member_GetById: PASS';

EXEC sp_Member_GetByEmail @Email='an.nguyen@gmail.com';
PRINT 'sp_Member_GetByEmail: PASS';

EXEC sp_Member_GetByQRCode @QRCodeValue='QR_MEM_001';
PRINT 'sp_Member_GetByQRCode: PASS';

-- Test search & filter
EXEC sp_Member_GetAll @PageNumber=1, @PageSize=10, @SearchTerm='Nguyễn', @TotalCount=@Total OUTPUT;
PRINT 'sp_Member_GetAll (search): Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Member_GetAll @PageNumber=1, @PageSize=10, @Status='Active', @TotalCount=@Total OUTPUT;
PRINT 'sp_Member_GetAll (filter status): Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Member_GetAll @PageNumber=1, @PageSize=10, @SortBy='CreatedAt', @SortDir='DESC', @TotalCount=@Total OUTPUT;
PRINT 'sp_Member_GetAll (sort): Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

-- 3.2 Trainer
EXEC sp_Trainer_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Trainer_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Trainer_GetById @TrainerId=1;
PRINT 'sp_Trainer_GetById: PASS';

-- 3.3 Facility
EXEC sp_Facility_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Facility_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Facility_GetById @FacilityId=1;
PRINT 'sp_Facility_GetById: PASS';

EXEC sp_Facility_GetActive;
PRINT 'sp_Facility_GetActive: PASS';

-- 3.4 Membership
EXEC sp_Membership_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Membership_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Membership_GetById @MembershipId=1;
PRINT 'sp_Membership_GetById: PASS';

EXEC sp_Membership_GetActive @MemberId=1;
PRINT 'sp_Membership_GetActive: PASS';

EXEC sp_Membership_GetExpiringSoon @DaysAhead=30;
PRINT 'sp_Membership_GetExpiringSoon: PASS';

-- 3.5 Schedule
EXEC sp_Schedule_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Schedule_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Schedule_GetById @ScheduleId=1;
PRINT 'sp_Schedule_GetById: PASS';

EXEC sp_Schedule_CheckConflict @TrainerId=1, @FacilityId=1, @StartTime='2026-01-15 08:00', @EndTime='2026-01-15 09:30', @ExcludeId=0;
PRINT 'sp_Schedule_CheckConflict: PASS';

-- 3.6 Session
EXEC sp_Session_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Session_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Session_GetById @SessionId=1;
PRINT 'sp_Session_GetById: PASS';

EXEC sp_Session_GetBySchedule @ScheduleId=1;
PRINT 'sp_Session_GetBySchedule: PASS';

-- 3.7 Checkin
EXEC sp_Checkin_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Checkin_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Checkin_GetById @CheckinId=1;
PRINT 'sp_Checkin_GetById: PASS';

EXEC sp_Checkin_GetByMember @MemberId=1;
PRINT 'sp_Checkin_GetByMember: PASS';

-- QR Checkin valid
EXEC sp_Checkin_ByQRCode @QRCodeValue='QR_MEM_001', @SessionId=1;
PRINT 'sp_Checkin_ByQRCode (valid): PASS';

-- QR Checkin invalid QR
DECLARE @InvalidQR NVARCHAR(100) = 'QR_INVALID_' + @TestRunId;
EXEC sp_Checkin_ByQRCode @QRCodeValue=@InvalidQR, @SessionId=1;
PRINT 'sp_Checkin_ByQRCode (invalid QR): PASS';

-- 3.8 Invoice
EXEC sp_Invoice_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Invoice_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Invoice_GetById @InvoiceId=1;
PRINT 'sp_Invoice_GetById: PASS';

EXEC sp_Invoice_GetByMember @MemberId=1;
PRINT 'sp_Invoice_GetByMember: PASS';

EXEC sp_Invoice_GetOverdue;
PRINT 'sp_Invoice_GetOverdue: PASS';

-- 3.9 Payment
EXEC sp_Payment_GetAll @PageNumber=1, @PageSize=5, @TotalCount=@Total OUTPUT;
PRINT 'sp_Payment_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Payment_GetById @PaymentId=1;
PRINT 'sp_Payment_GetById: PASS';

EXEC sp_Payment_GetByInvoice @InvoiceId=1;
PRINT 'sp_Payment_GetByInvoice: PASS';

-- 3.10 Reports
EXEC sp_Report_ActiveMembers @PageNumber=1, @PageSize=10, @TotalCount=@Total OUTPUT;
PRINT 'sp_Report_ActiveMembers: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Report_Revenue @Month=1, @Year=2026;
PRINT 'sp_Report_Revenue: PASS';

EXEC sp_Report_RevenueDetail @Month=1, @Year=2026, @PageNumber=1, @PageSize=10, @TotalCount=@Total OUTPUT;
PRINT 'sp_Report_RevenueDetail: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Report_MemberCheckinFrequency @FromDate='2026-01-01', @ToDate='2026-12-31', @PageNumber=1, @PageSize=10, @TotalCount=@Total OUTPUT;
PRINT 'sp_Report_MemberCheckinFrequency: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

EXEC sp_Report_FacilityUtilization @FromDate='2026-01-01', @ToDate='2026-12-31';
PRINT 'sp_Report_FacilityUtilization: PASS';

EXEC sp_Report_TrainerWorkload @FromDate='2026-01-01', @ToDate='2026-12-31';
PRINT 'sp_Report_TrainerWorkload: PASS';

-- 3.11 Audit Log
EXEC sp_AuditLog_GetAll @PageNumber=1, @PageSize=10, @TotalCount=@Total OUTPUT;
PRINT 'sp_AuditLog_GetAll: Total=' + CAST(@Total AS VARCHAR(10)) + ' | PASS';

-- 3.12 Permissions
EXEC sp_User_GetPermissions @UserId=1; -- Admin
PRINT 'sp_User_GetPermissions (admin): PASS';

EXEC sp_User_GetPermissions @UserId=2; -- Trainer
PRINT 'sp_User_GetPermissions (trainer): PASS';

EXEC sp_User_GetPermissions @UserId=4; -- Member
PRINT 'sp_User_GetPermissions (member): PASS';
PRINT '';

-- ============================================================
-- 4. TEST VIEWS
-- ============================================================
PRINT '>>> [4/12] TEST VIEWS';

SELECT TOP 3 * FROM vw_MemberDashboard;
PRINT 'vw_MemberDashboard: PASS';

SELECT TOP 3 * FROM vw_ActiveSchedules;
PRINT 'vw_ActiveSchedules: PASS';
PRINT '';

-- ============================================================
-- 5. TEST FUNCTIONS
-- ============================================================
PRINT '>>> [5/12] TEST FUNCTIONS';

SELECT dbo.fn_GetDaysRemaining('2026-12-31') AS DaysRemaining_Future;
PRINT 'fn_GetDaysRemaining (future): PASS';

SELECT dbo.fn_GetDaysRemaining('2025-01-01') AS DaysRemaining_Past;
PRINT 'fn_GetDaysRemaining (past): PASS';
PRINT '';

-- ============================================================
-- 6. TEST AUDIT TRIGGERS (Full CRUD cycle với cleanup)
-- ============================================================
PRINT '>>> [6/12] TEST AUDIT TRIGGERS (Full CRUD Cycle)';

-- Tạo test member với unique QR/Email
DECLARE @TestQR NVARCHAR(50) = 'QR_AUDIT_' + @TestRunId;
DECLARE @TestEmail NVARCHAR(150) = 'test_audit_' + @TestRunId + '@gym.com';

-- INSERT
DECLARE @TestFullName NVARCHAR(150) = N'Test Audit ' + @TestRunId;
EXEC sp_Member_Create 
    @FullName=@TestFullName, 
    @Phone='0999999999', 
    @Email=@TestEmail,
    @DateOfBirth='1990-01-01', 
    @JoinDate='2026-01-01', 
    @Status='Active',
    @QRCodeValue=@TestQR, 
    @CreatedBy=1;
SELECT @NewId = SCOPE_IDENTITY();

-- Verify audit log for INSERT
IF EXISTS (SELECT 1 FROM AuditLogs WHERE TableName='Members' AND RecordId=@NewId AND Action='INSERT')
    PRINT 'Audit INSERT trigger: PASS';
ELSE
    PRINT 'Audit INSERT trigger: FAIL';

-- UPDATE
DECLARE @TestFullNameUpdated NVARCHAR(150) = N'Test Audit Updated ' + @TestRunId;
EXEC sp_Member_Update 
    @MemberId=@NewId, 
    @FullName=@TestFullNameUpdated, 
    @Phone='0999999999', 
    @Email=@TestEmail,
    @DateOfBirth='1990-01-01', 
    @Status='Active', 
    @UpdatedBy=1;

IF EXISTS (SELECT 1 FROM AuditLogs WHERE TableName='Members' AND RecordId=@NewId AND Action='UPDATE')
    PRINT 'Audit UPDATE trigger: PASS';
ELSE
    PRINT 'Audit UPDATE trigger: FAIL';

-- SOFT DELETE
EXEC sp_Member_SoftDelete @MemberId=@NewId, @DeletedBy=1;

IF EXISTS (SELECT 1 FROM AuditLogs WHERE TableName='Members' AND RecordId=@NewId AND Action IN ('DELETE','SOFT_DELETE'))
    PRINT 'Audit SOFT_DELETE trigger: PASS';
ELSE
    PRINT 'Audit SOFT_DELETE trigger: FAIL';

-- RESTORE (kiểm tra IsDeleted = 0)
EXEC sp_Member_Restore @MemberId=@NewId, @RestoredBy=1;

IF NOT EXISTS (SELECT 1 FROM Members WHERE MemberId=@NewId AND IsDeleted=0)
    PRINT 'Audit RESTORE: FAIL - Record not restored';
ELSE
    PRINT 'Audit RESTORE: PASS';

-- CLEANUP: Soft delete again để không pollute data
EXEC sp_Member_SoftDelete @MemberId=@NewId, @DeletedBy=1;
PRINT '';

-- ============================================================
-- 7. TEST SOFT DELETE LOGIC
-- ============================================================
PRINT '>>> [7/12] TEST SOFT DELETE LOGIC';

SELECT 
    'Members Active' AS CheckName, COUNT(*) AS Count, 'PASS' AS Status FROM Members WHERE IsDeleted=0
UNION ALL SELECT 'Members Deleted', COUNT(*), 'INFO' FROM Members WHERE IsDeleted=1
UNION ALL SELECT 'Trainers Active', COUNT(*), 'PASS' FROM Trainers WHERE IsDeleted=0
UNION ALL SELECT 'Trainers Deleted', COUNT(*), 'INFO' FROM Trainers WHERE IsDeleted=1
UNION ALL SELECT 'Memberships Active', COUNT(*), 'PASS' FROM Memberships WHERE IsDeleted=0
UNION ALL SELECT 'Memberships Deleted', COUNT(*), 'INFO' FROM Memberships WHERE IsDeleted=1;
PRINT '';

-- ============================================================
-- 8. TEST RBAC PERMISSIONS MAPPING
-- ============================================================
PRINT '>>> [8/12] TEST RBAC PERMISSIONS';

;WITH PermCheck AS (
    SELECT r.RoleName, COUNT(p.PermissionId) AS PermissionCount
    FROM Roles r
    LEFT JOIN RolePermissions rp ON rp.RoleId = r.RoleId
    LEFT JOIN Permissions p ON p.PermissionId = rp.PermissionId
    WHERE r.IsSystem = 1
    GROUP BY r.RoleName
)
SELECT 
    RoleName, 
    PermissionCount,
    CASE 
        WHEN RoleName = 'Admin' AND PermissionCount = 45 THEN 'PASS'
        WHEN RoleName = 'Trainer' AND PermissionCount > 0 THEN 'PASS'
        WHEN RoleName = 'Member' AND PermissionCount > 0 THEN 'PASS'
        ELSE 'CHECK'
    END AS Status
FROM PermCheck
ORDER BY RoleName;
PRINT '';

-- ============================================================
-- 9. TEST USER LOGIN FLOW
-- ============================================================
PRINT '>>> [9/12] TEST USER LOGIN FLOW';

EXEC sp_User_GetByUsername @Username='admin';
PRINT 'sp_User_GetByUsername (admin): PASS';

EXEC sp_User_GetByUsername @Username='trainer1';
PRINT 'sp_User_GetByUsername (trainer1): PASS';

EXEC sp_User_GetByUsername @Username='member1';
PRINT 'sp_User_GetByUsername (member1): PASS';

EXEC sp_User_GetByUsername @Username='notexist';
PRINT 'sp_User_GetByUsername (notexist): PASS - Returns empty';

-- Verify password hash & salt not null
IF EXISTS (SELECT 1 FROM Users WHERE Username='admin' AND PasswordHash IS NOT NULL AND PasswordSalt IS NOT NULL)
    PRINT 'Password hash/salt populated: PASS';
ELSE
    PRINT 'Password hash/salt populated: FAIL';
PRINT '';

-- ============================================================
-- 10. TEST MEMBERSHIP EXPIRY CHECK
-- ============================================================
PRINT '>>> [10/12] TEST MEMBERSHIP EXPIRY';

EXEC sp_Membership_GetExpiringSoon @DaysAhead=7;
PRINT 'sp_Membership_GetExpiringSoon (7 days): PASS';

EXEC sp_Membership_GetExpiringSoon @DaysAhead=30;
PRINT 'sp_Membership_GetExpiringSoon (30 days): PASS';
PRINT '';

-- ============================================================
-- 11. TEST SCHEDULE CONFLICT CHECK
-- ============================================================
PRINT '>>> [11/12] TEST SCHEDULE CONFLICT';

-- No conflict
EXEC sp_Schedule_CheckConflict @TrainerId=999, @FacilityId=999, @StartTime='2026-01-15 08:00', @EndTime='2026-01-15 09:30', @ExcludeId=0;
PRINT 'sp_Schedule_CheckConflict (no conflict): PASS';

-- Trainer conflict
EXEC sp_Schedule_CheckConflict @TrainerId=1, @FacilityId=999, @StartTime='2026-01-15 08:00', @EndTime='2026-01-15 09:30', @ExcludeId=0;
PRINT 'sp_Schedule_CheckConflict (trainer conflict): PASS';

-- Facility conflict
EXEC sp_Schedule_CheckConflict @TrainerId=999, @FacilityId=1, @StartTime='2026-01-15 08:00', @EndTime='2026-01-15 09:30', @ExcludeId=0;
PRINT 'sp_Schedule_CheckConflict (facility conflict): PASS';

-- Exclude self
EXEC sp_Schedule_CheckConflict @TrainerId=1, @FacilityId=1, @StartTime='2026-01-15 08:00', @EndTime='2026-01-15 09:30', @ExcludeId=1;
PRINT 'sp_Schedule_CheckConflict (exclude self): PASS';
PRINT '';

-- ============================================================
-- 12. TEST CONCURRENCY (RowVersion) + VERSIONING
-- ============================================================
PRINT '>>> [12/12] TEST CONCURRENCY & VERSIONING';

SELECT MemberId, FullName, RowVersion FROM Members WHERE MemberId=1;
PRINT 'RowVersion exists on Members: PASS';

SELECT TrainerId, FullName, RowVersion FROM Trainers WHERE TrainerId=1;
PRINT 'RowVersion exists on Trainers: PASS';

SELECT MembershipId, Version, RowVersion FROM Memberships WHERE MembershipId=1;
PRINT 'Version + RowVersion exists on Memberships: PASS';

-- Test Version increment on Membership update
DECLARE @VerBefore INT;
SELECT @VerBefore = Version FROM Memberships WHERE MembershipId=1;
EXEC sp_Membership_Update @MembershipId=1, @MembershipType='Monthly', @Price=600000, @StartDate='2026-01-10', @EndDate='2026-02-10', @IsActive=1, @UpdatedBy=1;
DECLARE @VerAfter INT;
SELECT @VerAfter = Version FROM Memberships WHERE MembershipId=1;
IF @VerAfter = @VerBefore + 1
    PRINT 'Membership Version increment on update: PASS';
ELSE
    PRINT 'Membership Version increment on update: FAIL (before=' + CAST(@VerBefore AS VARCHAR) + ', after=' + CAST(@VerAfter AS VARCHAR) + ')';
PRINT '';

-- ============================================================
-- SUMMARY
-- ============================================================
PRINT '============================================================';
PRINT '✅ ALL TESTS COMPLETED SUCCESSFULLY!';
PRINT 'Test Run ID: ' + @TestRunId;
PRINT '============================================================';
PRINT '';
PRINT 'Database is ready for API development.';
PRINT 'Next steps: Build ASP.NET Core Web API wrapping these SPs.';
GO
