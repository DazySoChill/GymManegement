# 🔄 MIGRATION GUIDE
## Từ SQL cũ sang SQL2 mới

---

## ⚠️ LƯU Ý QUAN TRỌNG

**SQL2 KHÔNG TƯƠNG THÍCH với database cũ!**

Schema mới đã thay đổi fundamental:
- Bỏ Roles, Permissions, RolePermissions tables
- Users.Role từ FK → String
- Bỏ OTP/RefreshTokens tables
- Bỏ nhiều columns không cần thiết

---

## 🎯 DECISION TREE

### CÂU HỎI 1: Bạn có data production quan trọng không?

**❌ KHÔNG (dev/test environment)**
→ Đi đến **OPTION 1: Fresh Start**

**✅ CÓ (production data cần giữ)**
→ Đi đến **OPTION 2: Data Migration**

---

## 🆕 OPTION 1: FRESH START (RECOMMENDED)

**Dành cho**: Dev/Test environment, không có data quan trọng

### Step 1: Backup (optional, nếu muốn giữ reference)
```sql
-- Backup entire database
BACKUP DATABASE GymDb TO DISK = 'C:\Backup\GymDb_old.bak'
```

### Step 2: Drop old database
```bash
# Chạy file
sqlcmd -S localhost -U sa -P yourpassword -i SQL2/00_DROP_AND_CREATE_DB.sql
```

Hoặc manual:
```sql
USE master;
GO

ALTER DATABASE GymDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE GymDb;
GO
```

### Step 3: Create new database
```sql
CREATE DATABASE GymDb;
GO
```

### Step 4: Run SQL2 scripts
```bash
# 1. Schema
sqlcmd -S localhost -U sa -P yourpassword -d GymDb -i SQL2/01_SCHEMA_SIMPLIFIED.sql

# 2. Seed data
sqlcmd -S localhost -U sa -P yourpassword -d GymDb -i SQL2/02_SEED_DATA.sql

# 3. Stored procedures
sqlcmd -S localhost -U sa -P yourpassword -d GymDb -i SQL2/03_STORED_PROCEDURES.sql
```

### Step 5: Update code
→ Xem `CHANGES_FOR_CODE.md`

### Step 6: Test
```bash
# Test login
curl -X POST http://localhost:5000/api/Auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"gym@2026"}'
```

**✅ DONE!**

---

## 🔄 OPTION 2: DATA MIGRATION (COMPLEX)

**Dành cho**: Production data cần migrate

### ⚠️ CẢNH BÁO
- Migration script phức tạp
- Một số data sẽ **MẤT** (OTP, PasswordResetToken, RefreshTokens)
- Phải manual map Roles → Role string
- Phải manual link Users → Members by Email

### Prerequisites
1. Backup toàn bộ database
2. Test migration trên copy của production DB trước
3. Có downtime window (~ 30 phút)

---

### Migration Script

**File: `SQL2/MIGRATE_FROM_OLD.sql`**

```sql
-- ============================================================
-- DATA MIGRATION: Old GymDb → SQL2 GymDb
-- CẢNH BÁO: Test kỹ trước khi chạy production!
-- ============================================================

USE master;
GO

-- Step 1: Backup old database
BACKUP DATABASE GymDb TO DISK = 'C:\Backup\GymDb_before_migration.bak';
GO

-- Step 2: Create new database with different name (for safety)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GymDb_New')
    DROP DATABASE GymDb_New;
GO

CREATE DATABASE GymDb_New;
GO

USE GymDb_New;
GO

-- Step 3: Run SQL2 schema
-- (Copy content from 01_SCHEMA_SIMPLIFIED.sql here or run separately)

-- Step 4: Migrate data

-- 4.1 Migrate Members (straightforward)
INSERT INTO GymDb_New.dbo.Members (MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue, CreatedAt, IsDeleted)
SELECT 
    MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, 
    Status, QRCodeValue, CreatedAt, IsDeleted
FROM GymDb.dbo.Members
WHERE IsDeleted = 0;
GO

-- 4.2 Migrate Trainers
INSERT INTO GymDb_New.dbo.Trainers (TrainerId, FullName, Phone, Email, Specialization, CreatedAt, IsDeleted)
SELECT 
    TrainerId, FullName, Phone, Email, Specialization, CreatedAt, IsDeleted
FROM GymDb.dbo.Trainers
WHERE IsDeleted = 0;
GO

-- 4.3 Migrate Users (COMPLEX - need to map RoleId → Role string)
INSERT INTO GymDb_New.dbo.Users (UserId, Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, IsDeleted)
SELECT 
    u.UserId,
    u.Username,
    u.PasswordHash,
    COALESCE(m.FullName, t.FullName, 'Unknown') AS FullName,
    COALESCE(m.Email, t.Email, u.Username + '@gym.com') AS Email,
    CASE 
        WHEN r.RoleName = 'Admin' THEN 'Admin'
        WHEN r.RoleName = 'Trainer' THEN 'Trainer'
        WHEN r.RoleName = 'Member' THEN 'Member'
        ELSE 'Member'
    END AS Role,
    u.IsActive,
    u.CreatedAt,
    u.IsDeleted
FROM GymDb.dbo.Users u
LEFT JOIN GymDb.dbo.Roles r ON r.RoleId = u.RoleId
LEFT JOIN GymDb.dbo.Members m ON m.MemberId = u.MemberId
LEFT JOIN GymDb.dbo.Trainers t ON t.TrainerId = u.TrainerId
WHERE u.IsDeleted = 0 AND u.IsActive = 1;  -- Only active users
GO

-- 4.4 Migrate Facilities
INSERT INTO GymDb_New.dbo.Facilities (FacilityId, FacilityName, FacilityType, Capacity, Status, Description, CreatedAt, IsDeleted)
SELECT 
    FacilityId, 
    Name AS FacilityName,
    'Room' AS FacilityType,  -- ⚠️ MANUAL: Phải phân loại Room/Equipment
    NULL AS Capacity,
    CASE WHEN IsActive = 1 THEN 'Available' ELSE 'Unavailable' END AS Status,
    Description,
    CreatedAt,
    IsDeleted
FROM GymDb.dbo.Facilities
WHERE IsDeleted = 0;
GO

-- 4.5 Migrate Memberships
INSERT INTO GymDb_New.dbo.Memberships (MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, Status, CreatedAt, IsDeleted)
SELECT 
    MembershipId, MemberId, MembershipType, Price, StartDate, EndDate,
    CASE 
        WHEN IsActive = 1 AND EndDate >= CAST(GETDATE() AS DATE) THEN 'Active'
        WHEN EndDate < CAST(GETDATE() AS DATE) THEN 'Expired'
        ELSE 'Cancelled'
    END AS Status,
    CreatedAt, IsDeleted
FROM GymDb.dbo.Memberships
WHERE IsDeleted = 0;
GO

-- 4.6 Migrate Schedules
INSERT INTO GymDb_New.dbo.Schedules (ScheduleId, MemberId, TrainerId, FacilityId, ScheduledDate, StartTime, EndTime, Status, CreatedAt, IsDeleted)
SELECT 
    ScheduleId, MemberId, TrainerId, FacilityId,
    CAST(StartTime AS DATE) AS ScheduledDate,
    CAST(StartTime AS TIME) AS StartTime,
    CAST(EndTime AS TIME) AS EndTime,
    'Scheduled' AS Status,  -- ⚠️ MANUAL: Old schema không có Status
    CreatedAt, IsDeleted
FROM GymDb.dbo.Schedules
WHERE IsDeleted = 0;
GO

-- 4.7 Migrate Sessions
INSERT INTO GymDb_New.dbo.Sessions (SessionId, ScheduleId, ActualStartTime, ActualEndTime, CreatedAt, IsDeleted)
SELECT 
    SessionId, ScheduleId,
    NULL AS ActualStartTime,  -- ⚠️ Old schema không có
    NULL AS ActualEndTime,
    CreatedAt, IsDeleted
FROM GymDb.dbo.Sessions
WHERE IsDeleted = 0;
GO

-- 4.8 Migrate Checkins
INSERT INTO GymDb_New.dbo.Checkins (CheckinId, MemberId, SessionId, CheckinTime, CheckinMethod, CreatedAt, IsDeleted)
SELECT 
    CheckinId, MemberId, SessionId, CheckinTime, CheckinMethod, CreatedAt, IsDeleted
FROM GymDb.dbo.Checkins
WHERE IsDeleted = 0;
GO

-- 4.9 Migrate Invoices
INSERT INTO GymDb_New.dbo.Invoices (InvoiceId, MemberId, MembershipId, Amount, IssueDate, DueDate, Status, Description, CreatedAt, IsDeleted)
SELECT 
    InvoiceId, MemberId, 
    NULL AS MembershipId,  -- ⚠️ Old schema không link Membership
    TotalAmount AS Amount, InvoiceDate AS IssueDate, DueDate, Status, 
    'Migrated invoice' AS Description,
    CreatedAt, IsDeleted
FROM GymDb.dbo.Invoices
WHERE IsDeleted = 0;
GO

-- 4.10 Migrate Payments
INSERT INTO GymDb_New.dbo.Payments (PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, CreatedAt, IsDeleted)
SELECT 
    PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, CreatedAt, IsDeleted
FROM GymDb.dbo.Payments
WHERE IsDeleted = 0;
GO

-- Step 5: Verify migration
PRINT 'Migration Summary:';
PRINT '  Old Members: ' + CAST((SELECT COUNT(*) FROM GymDb.dbo.Members WHERE IsDeleted = 0) AS NVARCHAR);
PRINT '  New Members: ' + CAST((SELECT COUNT(*) FROM GymDb_New.dbo.Members) AS NVARCHAR);
PRINT '  Old Users: ' + CAST((SELECT COUNT(*) FROM GymDb.dbo.Users WHERE IsDeleted = 0) AS NVARCHAR);
PRINT '  New Users: ' + CAST((SELECT COUNT(*) FROM GymDb_New.dbo.Users) AS NVARCHAR);

-- Step 6: Manual verification queries
SELECT 'Old Users with Roles' AS Label, u.UserId, u.Username, r.RoleName
FROM GymDb.dbo.Users u
LEFT JOIN GymDb.dbo.Roles r ON r.RoleId = u.RoleId
WHERE u.IsDeleted = 0;

SELECT 'New Users with Role String' AS Label, UserId, Username, Role
FROM GymDb_New.dbo.Users;

-- Step 7: Switch databases (MANUAL - do this during downtime)
-- USE master;
-- ALTER DATABASE GymDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
-- DROP DATABASE GymDb;
-- ALTER DATABASE GymDb_New MODIFY NAME = GymDb;
-- GO
```

---

### Post-Migration Checklist

- [ ] Verify user count matches
- [ ] Test login với users cũ
- [ ] Verify Members có QRCode
- [ ] Verify Memberships có status đúng
- [ ] Test tất cả APIs
- [ ] Seed missing Facilities (nếu cần)
- [ ] Manual fix Facility types (Room vs Equipment)
- [ ] Update code theo CHANGES_FOR_CODE.md

---

## 🚫 DATA SẼ MẤT

**Không thể migrate** (schema không tồn tại):
1. ❌ EmailVerificationOTP records
2. ❌ PasswordResetToken records
3. ❌ RefreshTokens records
4. ❌ AuditLogs records (nếu muốn giữ, export ra file)
5. ❌ Users.PasswordSalt (không cần, BCrypt có salt)
6. ❌ Users.FailedLoginCount, LockedUntil, LastLoginAt

**Cần manual adjustment**:
- ⚠️ Facilities: Phải phân loại Room vs Equipment
- ⚠️ Schedules: Old schema có datetime, new schema tách date + time
- ⚠️ Sessions: Old schema thiếu ActualStartTime/ActualEndTime

---

## 📊 COMPARISON

| Aspect | Old SQL | SQL2 | Migration Difficulty |
|--------|---------|------|---------------------|
| **Tables** | 15+ | 10 | ⚠️ Medium (bỏ 5+ tables) |
| **Users** | RoleId FK | Role string | 🔴 Hard (map FK → string) |
| **Members** | Same | Same | ✅ Easy (1:1 copy) |
| **Trainers** | Same | Same | ✅ Easy (1:1 copy) |
| **Facilities** | Name only | Name + Type | ⚠️ Medium (manual classify) |
| **Memberships** | IsActive | Status enum | ⚠️ Medium (map bool → enum) |
| **Schedules** | DateTime | Date + Time | ⚠️ Medium (split columns) |
| **Invoices** | Same | + MembershipId | ✅ Easy (set null) |

---

## 🎯 RECOMMENDATION

### For DEV/TEST
→ **Use OPTION 1 (Fresh Start)**
- Nhanh, đơn giản
- Seed data sẵn 2000+ records
- Không phải deal với migration complexity

### For PRODUCTION
→ **Evaluate carefully**
- Có bao nhiêu users hiện tại?
- Có bao nhiêu memberships active?
- Data có quan trọng không?

Nếu < 100 users → Consider fresh start + manual re-create important records
Nếu > 100 users → Use OPTION 2 (Migration) + careful testing

---

## 📞 SUPPORT

**Stuck with migration?**
1. Test trên database copy trước
2. Verify từng table migration riêng lẻ
3. Check counts (old vs new)
4. Backup trước khi switch

**Good luck! 🚀**
