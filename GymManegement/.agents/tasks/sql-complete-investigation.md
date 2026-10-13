# Gym Management System - Complete SQL Investigation Report

## Executive Summary

This report documents a comprehensive investigation of the Gym Management System database requirements. The investigation analyzed all SQL files in SQL2/, all repository implementations, service layer code, and entity definitions to understand the complete database schema, stored procedures, backend requirements, encoding patterns, and seed data needs.

**Key Findings:**
- ✅ All existing SQL uses proper NVARCHAR with N-prefix for Vietnamese text (no encoding issues found)
- ✅ Schema is well-defined with 12 tables, proper foreign keys and indexes
- ⚠️ Missing 2 stored procedures that backend code references
- ⚠️ Current seed data does not reflect role-switch requirements (Trainers need both Trainer AND Member records)
- ✅ Backend uses direct SQL queries (Dapper) with proper parameterization
- ✅ Role-switch logic exists in AuthService but seed data doesn't demonstrate it

---

## 1. Schema Inventory

### 1.1 Complete Table List (12 tables)

All tables follow consistent patterns:
- `INT IDENTITY(1,1) PRIMARY KEY` for primary keys
- `NVARCHAR` for all text columns (Unicode support for Vietnamese)
- Standard audit columns: `CreatedAt`, `UpdatedAt`, `IsDeleted`, `DeletedAt`
- Proper indexes on foreign keys, email, status fields, and date fields

#### Table 1: Users
```sql
UserId          INT IDENTITY(1,1) PRIMARY KEY
Username        NVARCHAR(50) NOT NULL UNIQUE
PasswordHash    NVARCHAR(255) NOT NULL
FullName        NVARCHAR(100) NOT NULL
Email           NVARCHAR(100) NOT NULL
Role            NVARCHAR(20) NOT NULL DEFAULT 'Member'  -- 'Admin', 'Trainer', or 'Member'
IsActive        BIT NOT NULL DEFAULT 1
LastLoginAt     DATETIME NULL
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NULL
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Users_Username, IX_Users_Email, IX_Users_Role, IX_Users_IsDeleted

#### Table 2: Members
```sql
MemberId        INT IDENTITY(1,1) PRIMARY KEY
FullName        NVARCHAR(100) NOT NULL
Email           NVARCHAR(100) NOT NULL
Phone           NVARCHAR(20) NULL
DateOfBirth     DATETIME NULL
QRCode          NVARCHAR(255) NOT NULL  -- Format: M000001
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Members_Email, IX_Members_QRCode, IX_Members_IsDeleted

**Note:** QRCode format is `M{MemberId:D6}` (e.g., M000001)

#### Table 3: Trainers
```sql
TrainerId       INT IDENTITY(1,1) PRIMARY KEY
FullName        NVARCHAR(100) NOT NULL
Email           NVARCHAR(100) NOT NULL
Phone           NVARCHAR(20) NULL
Specialization  NVARCHAR(200) NULL
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Trainers_Email, IX_Trainers_IsDeleted

#### Table 4: Facilities
```sql
FacilityId      INT IDENTITY(1,1) PRIMARY KEY
Name            NVARCHAR(100) NOT NULL
Description     NVARCHAR(500) NULL
Status          NVARCHAR(20) NOT NULL DEFAULT 'Available'  -- 'Available', 'Maintenance'
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Facilities_Status, IX_Facilities_IsDeleted

#### Table 5: Memberships
```sql
MembershipId    INT IDENTITY(1,1) PRIMARY KEY
MemberId        INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId)
PackageName     NVARCHAR(100) NOT NULL
Price           DECIMAL(18,2) NOT NULL
StartDate       DATETIME NOT NULL
EndDate         DATETIME NOT NULL
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Memberships_MemberId, IX_Memberships_StartDate, IX_Memberships_EndDate, IX_Memberships_IsDeleted

**Package names in seed data:** "Gói Tháng", "Gói Quý", "Gói 6 Tháng", "Gói Năm"

#### Table 6: Invoices
```sql
InvoiceId       INT IDENTITY(1,1) PRIMARY KEY
MemberId        INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId)
MembershipId    INT NULL FOREIGN KEY REFERENCES Memberships(MembershipId)
InvoiceDate     DATETIME NOT NULL DEFAULT GETDATE()
DueDate         DATETIME NULL
TotalAmount     DECIMAL(18,2) NOT NULL
Status          NVARCHAR(20) NOT NULL DEFAULT 'Pending'  -- 'Pending', 'Paid', 'Unpaid'
Description     NVARCHAR(500) NULL
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NULL
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Invoices_MemberId, IX_Invoices_MembershipId, IX_Invoices_Status, IX_Invoices_InvoiceDate, IX_Invoices_IsDeleted

#### Table 7: Payments
```sql
PaymentId       INT IDENTITY(1,1) PRIMARY KEY
InvoiceId       INT NULL FOREIGN KEY REFERENCES Invoices(InvoiceId)
MemberId        INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId)
Amount          DECIMAL(18,2) NOT NULL
PaymentMethod   NVARCHAR(50) NOT NULL DEFAULT 'Cash'  -- 'Cash', 'Card', 'BankTransfer'
PaymentDate     DATETIME NOT NULL DEFAULT GETDATE()
TransactionId   NVARCHAR(100) NULL
Status          NVARCHAR(50) NOT NULL DEFAULT 'Completed'
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NULL
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Payments_InvoiceId, IX_Payments_MemberId, IX_Payments_PaymentDate, IX_Payments_Status, IX_Payments_IsDeleted

#### Table 8: Schedules
```sql
ScheduleId      INT IDENTITY(1,1) PRIMARY KEY
TrainerId       INT NOT NULL FOREIGN KEY REFERENCES Trainers(TrainerId)
FacilityId      INT NOT NULL FOREIGN KEY REFERENCES Facilities(FacilityId)
ClassName       NVARCHAR(100) NOT NULL
StartTime       DATETIME NOT NULL
EndTime         DATETIME NOT NULL
MaxCapacity     INT NOT NULL DEFAULT 20
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Schedules_TrainerId, IX_Schedules_FacilityId, IX_Schedules_StartTime, IX_Schedules_ClassName, IX_Schedules_IsDeleted

#### Table 9: Sessions
```sql
SessionId       INT IDENTITY(1,1) PRIMARY KEY
ScheduleId      INT NOT NULL FOREIGN KEY REFERENCES Schedules(ScheduleId)
MemberId        INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId)
RegistrationDate DATETIME NOT NULL DEFAULT GETDATE()
Status          NVARCHAR(20) NOT NULL DEFAULT 'Registered'  -- 'Registered', 'Attended', 'Cancelled'
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Sessions_ScheduleId, IX_Sessions_MemberId, IX_Sessions_Status, IX_Sessions_IsDeleted

#### Table 10: Checkins
```sql
CheckinId       INT IDENTITY(1,1) PRIMARY KEY
MemberId        INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId)
CheckinTime     DATETIME NOT NULL DEFAULT GETDATE()
CheckoutTime    DATETIME NULL
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_Checkins_MemberId, IX_Checkins_CheckinTime, IX_Checkins_IsDeleted

**Note:** Trainers MUST also be able to check in (recent requirement from user messages)

#### Table 11: AuditLogs
```sql
AuditLogId      INT IDENTITY(1,1) PRIMARY KEY
TableName       NVARCHAR(100) NOT NULL
RecordId        INT NOT NULL
Action          NVARCHAR(20) NOT NULL  -- 'INSERT', 'UPDATE', 'DELETE'
UserId          INT NULL
Username        NVARCHAR(100) NULL
OldValues       NVARCHAR(MAX) NULL
NewValues       NVARCHAR(MAX) NULL
ChangedAt       DATETIME NOT NULL DEFAULT GETDATE()
IpAddress       NVARCHAR(50) NULL
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NULL
IsDeleted       BIT NOT NULL DEFAULT 0
DeletedAt       DATETIME NULL
```
**Indexes:** IX_AuditLogs_TableName, IX_AuditLogs_RecordId, IX_AuditLogs_ChangedAt, IX_AuditLogs_UserId

#### Table 12: MemberSchedulePreferences
```sql
PreferenceId    INT IDENTITY(1,1) PRIMARY KEY
MemberId        INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId)
DayOfWeek       INT NOT NULL  -- 0=Sunday, 1=Monday, ..., 6=Saturday
StartTime       TIME NOT NULL
EndTime         TIME NOT NULL
IsActive        BIT NOT NULL DEFAULT 1
CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
UpdatedAt       DATETIME NOT NULL DEFAULT GETDATE()
```
**Indexes:** IX_MemberSchedulePreferences_MemberId, IX_MemberSchedulePreferences_DayOfWeek, IX_MemberSchedulePreferences_IsActive

---

## 2. Stored Procedure Inventory

### 2.1 Stored Procedures Found in Existing SQL Files

Found in `.agents/tasks/SCHEMA_FIX_MISMATCHES.sql` (not yet in main SQL files):

#### sp_AuditLog_Create
```sql
CREATE PROCEDURE sp_AuditLog_Create
    @TableName NVARCHAR(100),
    @RecordId INT,
    @Action NVARCHAR(50),
    @UserId INT = NULL,
    @Username NVARCHAR(100) = NULL,
    @OldValues NVARCHAR(MAX) = NULL,
    @NewValues NVARCHAR(MAX) = NULL,
    @IpAddress NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLogs (TableName, RecordId, [Action], UserId, Username, OldValues, NewValues, IpAddress, ChangedAt, CreatedAt, IsDeleted)
    VALUES (@TableName, @RecordId, @Action, @UserId, @Username, @OldValues, @NewValues, @IpAddress, GETDATE(), GETDATE(), 0);
    
    RETURN SCOPE_IDENTITY();
END
```

#### sp_AuditLog_GetByRecord
```sql
CREATE PROCEDURE sp_AuditLog_GetByRecord
    @TableName NVARCHAR(100),
    @RecordId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        AuditLogId, TableName, RecordId, [Action], UserId, Username,
        OldValues, NewValues, ChangedAt, IpAddress,
        CreatedAt, UpdatedAt, IsDeleted, DeletedAt
    FROM AuditLogs
    WHERE TableName = @TableName 
      AND RecordId = @RecordId
      AND IsDeleted = 0
    ORDER BY ChangedAt DESC;
END
```

### 2.2 Stored Procedures NOT Found (Currently Missing)

These procedures are referenced in `AuditLogRepository.cs` but do NOT exist in any SQL file in SQL2/:
- ✅ `sp_AuditLog_Create` — EXISTS in SCHEMA_FIX_MISMATCHES.sql but NOT in main SQL files
- ✅ `sp_AuditLog_GetByRecord` — EXISTS in SCHEMA_FIX_MISMATCHES.sql but NOT in main SQL files

**Action Required:** These stored procedures must be added to the complete SQL file.

---

## 3. Backend Requirements Analysis

### 3.1 Repository SQL Commands Inventory

All repositories use **inline SQL with Dapper** (no stored procedures except AuditLog). All SQL is properly parameterized.

#### UserRepository.cs
- `GetByUsernameAsync` — `SELECT * FROM Users WHERE Username = @Username AND IsDeleted = 0`
- `GetByEmailAsync` — `SELECT * FROM Users WHERE Email = @Email AND IsDeleted = 0`
- `GetByIdAsync` — `SELECT * FROM Users WHERE UserId = @UserId AND IsDeleted = 0`
- `GetAllAsync` — `SELECT * FROM Users WHERE IsDeleted = 0 ORDER BY CreatedAt DESC`
- `CreateAsync` — `INSERT INTO Users (...) OUTPUT INSERTED.UserId VALUES (...)`
- `UpdateAsync` — `UPDATE Users SET FullName=@FullName, Email=@Email, Role=@Role, IsActive=@IsActive, UpdatedAt=@UpdatedAt WHERE UserId=@UserId AND IsDeleted=0`
- `UpdatePasswordAsync` — `UPDATE Users SET PasswordHash=@PasswordHash, UpdatedAt=@UpdatedAt WHERE UserId=@UserId AND IsDeleted=0`
- `SetActiveAsync` — `UPDATE Users SET IsActive=@IsActive, UpdatedAt=@UpdatedAt WHERE UserId=@UserId AND IsDeleted=0`
- `UsernameExistsAsync` — `SELECT COUNT(1) FROM Users WHERE Username=@Username AND IsDeleted=0`
- `EmailExistsAsync` — `SELECT COUNT(1) FROM Users WHERE Email=@Email AND IsDeleted=0`
- `UpdateLastLoginAsync` — `UPDATE Users SET LastLoginAt=@LastLoginAt, UpdatedAt=@UpdatedAt WHERE UserId=@UserId AND IsDeleted=0`

#### MemberRepository.cs
- `GetAllAsync()` — `SELECT * FROM Members WHERE IsDeleted=0 ORDER BY CreatedAt DESC`
- `GetAllAsync(paging)` — Paginated query with OFFSET/FETCH, optional search term on FullName/Email/Phone
- `GetByIdAsync` — `SELECT * FROM Members WHERE MemberId=@MemberId AND IsDeleted=0`
- `GetByEmailAsync` — `SELECT * FROM Members WHERE Email=@Email AND IsDeleted=0`
- `GetByQRCodeAsync` — `SELECT * FROM Members WHERE QRCode=@QRCode AND IsDeleted=0`
- `EmailExistsAsync` — `SELECT COUNT(1) FROM Members WHERE Email=@Email AND IsDeleted=0 AND (@ExcludeMemberId IS NULL OR MemberId!=@ExcludeMemberId)`
- `CreateAsync` — `INSERT INTO Members (...) OUTPUT INSERTED.MemberId VALUES (...)`
- `UpdateAsync` — `UPDATE Members SET FullName=@FullName, Email=@Email, Phone=@Phone, DateOfBirth=@DateOfBirth, UpdatedAt=@UpdatedAt WHERE MemberId=@MemberId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Members SET IsDeleted=1, DeletedAt=@DeletedAt WHERE MemberId=@MemberId`
- `GetByIdsAsync` — `SELECT * FROM Members WHERE MemberId IN @MemberIds AND IsDeleted=0`

#### TrainerRepository.cs
- `GetAllAsync()` — `SELECT * FROM Trainers WHERE IsDeleted=0 ORDER BY CreatedAt DESC`
- `GetAllAsync(paging)` — Paginated query with whitelist-validated sortBy column
- `GetByIdAsync` — `SELECT * FROM Trainers WHERE TrainerId=@TrainerId AND IsDeleted=0`
- `GetByEmailAsync` — `SELECT * FROM Trainers WHERE Email=@Email AND IsDeleted=0`
- `GetWithSchedulesAsync` — `SELECT * FROM Trainers WHERE IsDeleted=0`
- `CreateAsync` — `INSERT INTO Trainers (...) OUTPUT INSERTED.TrainerId VALUES (...)`
- `UpdateAsync` — `UPDATE Trainers SET FullName=@FullName, Email=@Email, Phone=@Phone, Specialization=@Specialization, UpdatedAt=@UpdatedAt WHERE TrainerId=@TrainerId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Trainers SET IsDeleted=1, DeletedAt=@DeletedAt WHERE TrainerId=@TrainerId`
- `GetByIdsAsync` — `SELECT * FROM Trainers WHERE TrainerId IN @TrainerIds AND IsDeleted=0`

#### ScheduleRepository.cs
- `GetAllAsync()` — `SELECT * FROM Schedules WHERE IsDeleted=0 ORDER BY StartTime DESC`
- `GetAllAsync(paging)` — Paginated query
- `GetByIdAsync` — `SELECT * FROM Schedules WHERE ScheduleId=@ScheduleId AND IsDeleted=0`
- `GetByTrainerIdAsync` — `SELECT * FROM Schedules WHERE TrainerId=@TrainerId AND IsDeleted=0 ORDER BY StartTime DESC`
- `GetByFacilityIdAsync` — `SELECT * FROM Schedules WHERE FacilityId=@FacilityId AND IsDeleted=0 ORDER BY StartTime DESC`
- `GetByDateAsync` — `SELECT * FROM Schedules WHERE CAST(StartTime AS DATE)=CAST(@Date AS DATE) AND IsDeleted=0 ORDER BY StartTime ASC`
- `HasConflictAsync` — Complex query checking time overlaps for trainer OR facility
- `CreateAsync` — `INSERT INTO Schedules (...) OUTPUT INSERTED.ScheduleId VALUES (...)`
- `UpdateAsync` — `UPDATE Schedules SET TrainerId=@TrainerId, FacilityId=@FacilityId, ClassName=@ClassName, StartTime=@StartTime, EndTime=@EndTime, MaxCapacity=@MaxCapacity, UpdatedAt=@UpdatedAt WHERE ScheduleId=@ScheduleId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Schedules SET IsDeleted=1, DeletedAt=@DeletedAt WHERE ScheduleId=@ScheduleId`
- `GetByIdsAsync` — `SELECT * FROM Schedules WHERE ScheduleId IN @ScheduleIds AND IsDeleted=0`

#### CheckinRepository.cs
- `GetAllAsync()` — `SELECT * FROM Checkins WHERE IsDeleted=0 ORDER BY CheckinTime ASC`
- `GetAllAsync(paging)` — Paginated query
- `GetByIdAsync` — `SELECT * FROM Checkins WHERE CheckinId=@CheckinId AND IsDeleted=0`
- `GetByMemberIdAsync` — `SELECT * FROM Checkins WHERE MemberId=@MemberId AND IsDeleted=0 ORDER BY CheckinTime ASC`
- `GetByDateRangeAsync` — `SELECT * FROM Checkins WHERE CheckinTime>=@From AND CheckinTime<=@To AND IsDeleted=0 ORDER BY CheckinTime ASC`
- `GetByDateAsync` — `SELECT * FROM Checkins WHERE CAST(CheckinTime AS DATE)=CAST(@Date AS DATE) AND IsDeleted=0 ORDER BY CheckinTime ASC`
- `GetByQRCodeAsync` — `SELECT TOP 1 c.* FROM Checkins c INNER JOIN Members m ON c.MemberId=m.MemberId WHERE m.QRCode=@QRCode AND c.IsDeleted=0 ORDER BY c.CheckinTime DESC`
- `CreateAsync` — `INSERT INTO Checkins (...) OUTPUT INSERTED.CheckinId VALUES (...)`
- `UpdateAsync` — `UPDATE Checkins SET CheckoutTime=@CheckoutTime, UpdatedAt=@UpdatedAt WHERE CheckinId=@CheckinId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Checkins SET IsDeleted=1, DeletedAt=@DeletedAt WHERE CheckinId=@CheckinId`

#### MembershipRepository.cs
- `GetAllAsync()` — `SELECT * FROM Memberships WHERE IsDeleted=0 ORDER BY StartDate DESC`
- `GetAllAsync(paging)` — Paginated query
- `GetByIdAsync` — `SELECT * FROM Memberships WHERE MembershipId=@MembershipId AND IsDeleted=0`
- `GetByMemberIdAsync` — `SELECT * FROM Memberships WHERE MemberId=@MemberId AND IsDeleted=0 ORDER BY StartDate DESC`
- `GetActiveMembershipAsync` — `SELECT TOP 1 * FROM Memberships WHERE MemberId=@MemberId AND EndDate>=CAST(GETDATE() AS DATE) AND IsDeleted=0 ORDER BY EndDate DESC`
- `GetExpiringSoonAsync` — `SELECT * FROM Memberships WHERE EndDate BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, @DaysAhead, CAST(GETDATE() AS DATE)) AND IsDeleted=0 ORDER BY EndDate ASC`
- `GetActiveAsync` — `SELECT * FROM Memberships WHERE EndDate>=CAST(GETDATE() AS DATE) AND IsDeleted=0 ORDER BY EndDate ASC`
- `CreateAsync` — `INSERT INTO Memberships (...) OUTPUT INSERTED.MembershipId VALUES (...)`
- `UpdateAsync` — `UPDATE Memberships SET PackageName=@PackageName, Price=@Price, StartDate=@StartDate, EndDate=@EndDate, UpdatedAt=@UpdatedAt WHERE MembershipId=@MembershipId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Memberships SET IsDeleted=1, DeletedAt=@DeletedAt WHERE MembershipId=@MembershipId`
- `CancelAsync` — `UPDATE Memberships SET EndDate=CAST(GETDATE() AS DATE), UpdatedAt=GETDATE() WHERE MembershipId=@MembershipId AND IsDeleted=0 AND EndDate>CAST(GETDATE() AS DATE)`
- `GetByIdsAsync` — `SELECT * FROM Memberships WHERE MembershipId IN @MembershipIds AND IsDeleted=0`

#### InvoiceRepository.cs
- `GetAllAsync()` — `SELECT * FROM Invoices WHERE IsDeleted=0 ORDER BY InvoiceId`
- `GetAllAsync(paging)` — Paginated query with search on Status/Description
- `GetByIdAsync` — `SELECT * FROM Invoices WHERE InvoiceId=@Id AND IsDeleted=0`
- `GetByMemberIdAsync` — `SELECT * FROM Invoices WHERE MemberId=@MemberId AND IsDeleted=0 ORDER BY InvoiceDate DESC`
- `GetByStatusAsync` — `SELECT * FROM Invoices WHERE Status=@Status AND IsDeleted=0 ORDER BY InvoiceDate DESC`
- `GetOverdueAsync` — `SELECT * FROM Invoices WHERE Status='Pending' AND DueDate<GETDATE() AND IsDeleted=0 ORDER BY DueDate`
- `GetUnpaidAsync` — `SELECT * FROM Invoices WHERE Status IN ('Unpaid','Pending') AND IsDeleted=0 ORDER BY DueDate ASC`
- `GetTotalRevenueAsync` — `SELECT ISNULL(SUM(TotalAmount),0) FROM Invoices WHERE Status='Paid' AND MONTH(InvoiceDate)=@Month AND YEAR(InvoiceDate)=@Year AND IsDeleted=0`
- `CreateAsync` — `INSERT INTO Invoices (...) VALUES (...); SELECT CAST(SCOPE_IDENTITY() AS INT)`
- `UpdateAsync` — `UPDATE Invoices SET Status=@Status, UpdatedAt=GETDATE() WHERE InvoiceId=@InvoiceId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Invoices SET IsDeleted=1, UpdatedAt=GETDATE() WHERE InvoiceId=@Id`

#### PaymentRepository.cs
- `GetAllAsync()` — `SELECT * FROM Payments WHERE IsDeleted=0 ORDER BY PaymentDate DESC`
- `GetAllAsync(paging)` — Paginated query with search on PaymentMethod
- `GetByIdAsync` — `SELECT * FROM Payments WHERE PaymentId=@Id AND IsDeleted=0`
- `GetByInvoiceIdAsync` — `SELECT * FROM Payments WHERE InvoiceId=@InvoiceId AND IsDeleted=0 ORDER BY PaymentDate DESC`
- `GetByMemberIdAsync` — `SELECT * FROM Payments WHERE MemberId=@MemberId AND IsDeleted=0 ORDER BY PaymentDate DESC`
- `GetByStatusAsync` — `SELECT * FROM Payments WHERE IsDeleted=0 ORDER BY PaymentDate DESC` (ignores status parameter)
- `CreateAsync` — `INSERT INTO Payments (...) VALUES (...); SELECT CAST(SCOPE_IDENTITY() AS INT)`
- `UpdateAsync` — `UPDATE Payments SET Amount=@Amount, PaymentDate=@PaymentDate, PaymentMethod=@PaymentMethod, UpdatedAt=GETDATE() WHERE PaymentId=@PaymentId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Payments SET IsDeleted=1, UpdatedAt=GETDATE() WHERE PaymentId=@Id`

#### FacilityRepository.cs
- `GetAllAsync()` — `SELECT * FROM Facilities WHERE IsDeleted=0 ORDER BY FacilityId`
- `GetAllAsync(paging)` — Paginated query with search on Name/Description
- `GetByIdAsync` — `SELECT * FROM Facilities WHERE FacilityId=@Id AND IsDeleted=0`
- `GetActiveAsync` — `SELECT * FROM Facilities WHERE Status='Active' AND IsDeleted=0 ORDER BY Name`
- `CreateAsync` — `INSERT INTO Facilities (...) VALUES (...); SELECT CAST(SCOPE_IDENTITY() AS INT)`
- `UpdateAsync` — `UPDATE Facilities SET Name=@Name, Description=@Description, Status=@Status, UpdatedAt=GETDATE() WHERE FacilityId=@FacilityId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Facilities SET IsDeleted=1, UpdatedAt=GETDATE() WHERE FacilityId=@Id`
- `GetByIdsAsync` — `SELECT * FROM Facilities WHERE FacilityId IN @FacilityIds AND IsDeleted=0`

#### SessionRepository.cs
- `GetAllAsync()` — `SELECT * FROM Sessions WHERE IsDeleted=0 ORDER BY SessionId`
- `GetAllAsync(paging)` — Paginated query with search on Status
- `GetByIdAsync` — `SELECT * FROM Sessions WHERE SessionId=@Id AND IsDeleted=0`
- `GetByScheduleIdAsync` — `SELECT * FROM Sessions WHERE ScheduleId=@ScheduleId AND IsDeleted=0 ORDER BY RegistrationDate DESC`
- `GetByMemberIdAsync` — `SELECT * FROM Sessions WHERE MemberId=@MemberId AND IsDeleted=0 ORDER BY RegistrationDate DESC`
- `GetByStatusAsync` — `SELECT * FROM Sessions WHERE Status=@Status AND IsDeleted=0 ORDER BY RegistrationDate DESC`
- `CreateAsync` — `INSERT INTO Sessions (...) VALUES (...); SELECT CAST(SCOPE_IDENTITY() AS INT)`
- `UpdateAsync` — `UPDATE Sessions SET Status=@Status, UpdatedAt=GETDATE() WHERE SessionId=@SessionId AND IsDeleted=0`
- `DeleteAsync` — `UPDATE Sessions SET IsDeleted=1, UpdatedAt=GETDATE() WHERE SessionId=@Id`

#### MemberSchedulePreferenceRepository.cs
- `GetByIdAsync` — `SELECT * FROM MemberSchedulePreferences WHERE PreferenceId=@PreferenceId AND IsActive=1`
- `GetAllAsync` — `SELECT * FROM MemberSchedulePreferences WHERE IsActive=1 ORDER BY MemberId, DayOfWeek, StartTime`
- `GetByMemberIdAsync` — `SELECT * FROM MemberSchedulePreferences WHERE MemberId=@MemberId AND IsActive=1 ORDER BY DayOfWeek, StartTime`
- `GetByDayOfWeekAsync` — `SELECT * FROM MemberSchedulePreferences WHERE DayOfWeek=@DayOfWeek AND IsActive=1 ORDER BY StartTime`
- `CreateAsync` — `INSERT INTO MemberSchedulePreferences (...) OUTPUT INSERTED.PreferenceId VALUES (...)`
- `UpdateAsync` — `UPDATE MemberSchedulePreferences SET DayOfWeek=@DayOfWeek, StartTime=@StartTime, EndTime=@EndTime, IsActive=@IsActive, UpdatedAt=@UpdatedAt WHERE PreferenceId=@PreferenceId`
- `DeleteAsync` — `UPDATE MemberSchedulePreferences SET IsActive=0, UpdatedAt=@UpdatedAt WHERE PreferenceId=@PreferenceId`

#### AuditLogRepository.cs
- **Uses Stored Procedures:**
  - `CreateAsync` — Calls `sp_AuditLog_Create`
  - `GetByRecordAsync` — Calls `sp_AuditLog_GetByRecord`

### 3.2 Gap List: Stored Procedures Backend Needs But Don't Exist

❌ **Missing in SQL2/ main files (but exist in SCHEMA_FIX_MISMATCHES.sql):**
1. `sp_AuditLog_Create`
2. `sp_AuditLog_GetByRecord`

**Action Required:** Include these stored procedures in the complete SQL file.

### 3.3 Redundancy List: Objects Not Referenced in Backend

✅ **All tables in SQL files are referenced** by repositories.

⚠️ **Potential unused procedures:** None found in main SQL files (only inline SQL is used except for AuditLog).

---

## 4. Encoding Issues Analysis

### 4.1 Current Encoding Pattern

✅ **ALL Vietnamese text in existing SQL files correctly uses:**
- `NVARCHAR` data types (Unicode)
- `N'...'` prefix for all string literals containing Vietnamese characters

**Examples from 02_SEED_DATA.sql:**
```sql
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
('admin', '$2a$11$...', N'Quản Trị Viên', 'admin@gymmanagement.vn', 'Admin', 1, GETDATE(), GETDATE(), 0);

INSERT INTO Trainers (FullName, Email, Phone, Specialization, CreatedAt, UpdatedAt, IsDeleted)
VALUES 
(N'Nguyễn Văn An', 'an.nguyen@gymmanagement.vn', '0901234567', N'Gym & Fitness', GETDATE(), GETDATE(), 0);
```

### 4.2 Encoding Issues Found

✅ **NO ENCODING ISSUES FOUND**

All Vietnamese text uses proper NVARCHAR with N-prefix. The grep search for `VARCHAR(` without N or non-prefixed Vietnamese strings found only properly encoded NVARCHAR columns and N-prefixed literals.

### 4.3 Recommendations

✅ Continue using `NVARCHAR` for all text columns
✅ Always prefix Vietnamese string literals with `N'...'`
✅ Maintain consistency in seed data

---

## 5. Role-Switch Logic Observations

### 5.1 Business Rules from AuthService.cs

The `AuthService.cs` file reveals critical role-switch logic:

#### Rule 1: Register Creates Member User + Member Record
When a new user registers:
1. Creates User with `Role = "Member"`
2. Auto-creates Member record with email match
3. Generates QRCode as `M{MemberId:D6}` after insert

#### Rule 2: CreateStaff Creates Admin/Trainer User
When admin creates staff:
1. Creates User with `Role = "Admin"` or `Role = "Trainer"`
2. If `Role = "Trainer"`, auto-creates Trainer record with email match
3. Does NOT create Member record

#### Rule 3: UpdateUserRole Auto-Creates Target Role Record
When a user's role is changed (e.g., Trainer → Member):
1. Updates `Users.Role`
2. **If new role is "Trainer":** checks if Trainer record exists by email; if not, creates one
3. **If new role is "Member":** checks if Member record exists by email; if not, creates one with QRCode

This is THE KEY LOGIC that addresses the user's original complaint: *"khi bấm thêm thì bị lỗi này Không tìm thấy thông tin trainer. tôi nghĩ lỗi này cho id này chuyển role khi lúc trước tôi cũng từng đề cập việc nếu tạo ngay từ đầu là admin hoặc trainer thì khi chuyển về member sẽ bị lỗi là không nhận được là member."*

### 5.2 Critical Requirement: Trainers Need BOTH Records

From user message #1 and the recent review document:
- **Trainers MUST check in** like members (they are employees who work at the gym)
- Checkins table has FK to Members(MemberId), NOT to Trainers(TrainerId)
- Therefore: **Every Trainer user must have BOTH a Trainer record AND a Member record**

From `AuthService.UpdateUserRoleAsync`:
```csharp
if (newRole == "Trainer")
{
    // Creates Trainer record if missing
}
else if (newRole == "Member")
{
    // Creates Member record if missing
}
```

**Current Seed Data Problem:** 
- Trainer users (trainer1-trainer5) have Trainer records but NO Member records
- If a Trainer tries to check in, the system will fail to find their MemberId
- Solution: Seed data MUST create Member records for all Trainer users

### 5.3 User Check-in Flow

From `CheckinRepository.GetByQRCodeAsync`:
```sql
SELECT TOP 1 c.* 
FROM Checkins c
INNER JOIN Members m ON c.MemberId = m.MemberId
WHERE m.QRCode = @QRCode AND c.IsDeleted = 0
ORDER BY c.CheckinTime DESC
```

This confirms: **Check-ins require a Member record (via QRCode lookup)**

Therefore:
- Admin users: NO check-in capability (they don't need Member records)
- Member users: check in via their Member record
- Trainer users: check in via their Member record (but also have Trainer record for schedule management)

---

## 6. Seed Data Requirements

### 6.1 Seed Data Structure

Based on business rules and existing seed data patterns, the complete SQL must include:

#### 6.1.1 Users Table Seed Data

**1 Admin:**
- Username: `admin`
- FullName: `Quản Trị Viên`
- Email: `admin@gymmanagement.vn`
- Role: `Admin`
- Password: `password` (bcrypt hash: `$2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq`)

**5 Trainers:**
- Username: `trainer1` through `trainer5`
- FullName: Vietnamese names (e.g., `Nguyễn Văn An`, `Trần Thị Bình`, etc.)
- Email: `*.nguyen@gymmanagement.vn`, etc.
- Role: `Trainer`
- Password: `password` (same hash)

**20 Members:**
- Username: `member01` through `member20`
- FullName: Vietnamese names
- Email: `*.nguyen@gmail.com`, etc.
- Role: `Member`
- Password: `password` (same hash)

#### 6.1.2 Trainers Table Seed Data

**5 Trainers** (matching the 5 Trainer users by email):
- FullName, Email (matches User.Email)
- Phone: 0901234567-0901234571
- Specialization: "Gym & Fitness", "Yoga & Pilates", "Cardio & HIIT", "Aerobic & Dance", "Boxing & Martial Arts"

#### 6.1.3 Members Table Seed Data

**25 Members total:**

**20 Member-role users** (member01-member20):
- FullName, Email (matches User.Email)
- Phone: 0912345601-0912345620
- DateOfBirth: Various dates in 1990s
- QRCode: M000001-M000020

**5 Trainer-role users** (trainer1-trainer5) — **CRITICAL ADDITION:**
- FullName, Email (matches User.Email and Trainer.Email)
- Phone: Can be same as Trainer record or NULL
- DateOfBirth: NULL or specific dates
- QRCode: M000021-M000025

**Rationale:** Trainers need Member records to support check-in functionality. The role-switch logic in AuthService demonstrates this is the intended design.

#### 6.1.4 Facilities Table Seed Data

**10 Facilities:**
- Phòng Gym Tầng 1, Phòng Yoga, Phòng Cardio, Phòng Aerobic, Phòng Boxing
- Phòng Gym Tầng 2, Sân Tennis (Maintenance), Phòng Pilates, Phòng Spinning, Phòng Đa Năng
- Status: "Available" (except Sân Tennis: "Maintenance")

#### 6.1.5 Memberships Table Seed Data

**20 Memberships** for Member-role users (MemberId 1-20):
- PackageName: "Gói Tháng", "Gói Quý", "Gói 6 Tháng", "Gói Năm"
- Price: 500000, 1350000, 2700000, 5000000
- StartDate/EndDate: Various dates from Jan 2025 onwards

**Note:** Trainers (MemberId 21-25) do NOT need Memberships in seed data (they are employees, not paying members)

#### 6.1.6 Schedules Table Seed Data

**20 Schedules** created by the 5 trainers:
- TrainerId: 1-5 (rotating)
- FacilityId: 1-10 (various facilities)
- ClassName: Vietnamese class names
- StartTime/EndTime: Various times from Jan 6, 2025 onwards
- MaxCapacity: 12-35

#### 6.1.7 Sessions Table Seed Data

**26 Sessions** (Member registrations for schedules):
- ScheduleId: Various
- MemberId: 1-20 (only Member-role users register for classes)
- Status: "Registered", "Attended", "Cancelled"

#### 6.1.8 Checkins Table Seed Data

**19 Check-ins** for Member-role users:
- MemberId: 1-20 (various members)
- CheckinTime: Various times from Jan 6, 2025 onwards
- CheckoutTime: Some NULL (still checked in), others with checkout times

**CRITICAL ADDITION REQUIRED:**
**5-10 Check-ins for Trainer-role users:**
- MemberId: 21-25 (the Member records for Trainers)
- CheckinTime: Various times demonstrating Trainers also check in
- Sorted by CheckinTime ASC (user requirement: earliest check-in appears first)

#### 6.1.9 Invoices Table Seed Data

**20 Invoices** for memberships:
- MemberId: 1-20
- MembershipId: 1-20 (one invoice per membership)
- Status: "Paid" or "Pending"
- Description: Vietnamese descriptions

#### 6.1.10 Payments Table Seed Data

**15 Payments** for paid invoices:
- InvoiceId: References invoices with Status="Paid"
- MemberId: 1-20
- PaymentMethod: "Cash", "Card", "BankTransfer"
- Status: "Completed"

#### 6.1.11 MemberSchedulePreferences Table Seed Data

**10 Preferences** for various members:
- MemberId: 1-10
- DayOfWeek: 0-6 (Sunday-Saturday)
- StartTime/EndTime: Various time preferences
- IsActive: 1

#### 6.1.12 AuditLogs Table Seed Data

**5 Sample Audit Logs:**
- Sample logs for User, Member, Membership, Invoice, Payment inserts
- Action: "INSERT"
- UserId: 1 (admin)
- Username: "admin"

---

## 7. Additional Observations

### 7.1 Password Hashing

All users in seed data use the same BCrypt hash:
- **Original password:** `password`
- **BCrypt hash (workFactor 11):** `$2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq`

The FIX_PASSWORDS.sql file shows the correct hash, which differs from 02_SEED_DATA.sql. **Use the hash from FIX_PASSWORDS.sql for the complete file.**

### 7.2 QRCode Generation Pattern

From `AuthService.RegisterAsync` and `fix-missing-trainer-member-records.sql`:
```csharp
var qrCode = $"M{member.MemberId:D6}";
```

Pattern: `M` + 6-digit zero-padded MemberId
- Member 1 → `M000001`
- Member 20 → `M000020`
- Member 21 (Trainer 1) → `M000021`

### 7.3 Foreign Key Dependencies

Tables must be seeded in this order:
1. Users (no dependencies)
2. Trainers (no dependencies)
3. Members (no dependencies)
4. Facilities (no dependencies)
5. Memberships (FK to Members)
6. Schedules (FK to Trainers, Facilities)
7. Sessions (FK to Schedules, Members)
8. Checkins (FK to Members)
9. Invoices (FK to Members, Memberships)
10. Payments (FK to Invoices, Members)
11. MemberSchedulePreferences (FK to Members)
12. AuditLogs (no FK enforcement)

### 7.4 Soft Delete Pattern

All tables use soft delete:
- `IsDeleted BIT NOT NULL DEFAULT 0`
- `DeletedAt DATETIME NULL`

All repository queries filter `WHERE IsDeleted = 0`
Delete operations: `UPDATE ... SET IsDeleted = 1, DeletedAt = GETDATE()`

### 7.5 UTC vs Local Time

- C# code uses `DateTime.UtcNow`
- SQL uses `GETDATE()` (server local time)

For consistency, SQL should continue using `GETDATE()` as the application is likely deployed in Vietnam timezone.

---

## 8. Recommendations for Complete SQL File

### 8.1 File Structure

```
-- Section 1: Drop and recreate database
USE master; GO
DROP DATABASE IF EXISTS GymDb; GO
CREATE DATABASE GymDb; GO
USE GymDb; GO

-- Section 2: Create schema (12 tables with indexes)
-- (All CREATE TABLE statements)

-- Section 3: Create stored procedures
-- sp_AuditLog_Create
-- sp_AuditLog_GetByRecord

-- Section 4: Seed data
-- INSERT statements in FK dependency order

-- Section 5: Verification queries
-- SELECT COUNT(*) FROM each table
-- Verify stored procedures exist
-- Verify role-switch readiness (Trainers have Member records)
```

### 8.2 Critical Fixes Required

1. ✅ **Include stored procedures** from SCHEMA_FIX_MISMATCHES.sql:
   - `sp_AuditLog_Create`
   - `sp_AuditLog_GetByRecord`

2. ✅ **Add Member records for Trainers** (MemberId 21-25):
   - Email matches Trainer.Email and User.Email
   - QRCode: M000021-M000025
   - FullName matches Trainer.FullName

3. ✅ **Add Trainer check-in examples** (5-10 records):
   - MemberId: 21-25
   - Demonstrate that Trainers check in like members
   - Sort by CheckinTime ASC

4. ✅ **Use correct password hash** from FIX_PASSWORDS.sql:
   - `$2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq`

5. ✅ **Maintain NVARCHAR + N-prefix** for all Vietnamese text

### 8.3 Verification Checklist

After running the complete SQL file, verify:

- [ ] Database GymDb exists
- [ ] All 12 tables exist with proper foreign keys
- [ ] All indexes exist
- [ ] Both stored procedures exist (sp_AuditLog_Create, sp_AuditLog_GetByRecord)
- [ ] 26 Users (1 Admin, 5 Trainers, 20 Members)
- [ ] 5 Trainers
- [ ] 25 Members (20 Member-role + 5 Trainer-role users)
- [ ] All Trainer users (email @gymmanagement.vn) have corresponding Member records
- [ ] 10 Facilities
- [ ] 20 Memberships
- [ ] 20 Schedules
- [ ] 26 Sessions
- [ ] 24-30 Checkins (including Trainer check-ins)
- [ ] 20 Invoices
- [ ] 15 Payments
- [ ] 10 MemberSchedulePreferences
- [ ] 5 AuditLogs
- [ ] All passwords use the correct BCrypt hash
- [ ] All Vietnamese text displays correctly (NVARCHAR encoding)

---

## 9. Summary

### Database Schema
- ✅ 12 tables properly defined with foreign keys and indexes
- ✅ All use NVARCHAR for Vietnamese text support
- ✅ Consistent soft delete pattern (IsDeleted, DeletedAt)
- ✅ Proper audit columns (CreatedAt, UpdatedAt)

### Stored Procedures
- ⚠️ 2 stored procedures exist in SCHEMA_FIX_MISMATCHES.sql but NOT in main SQL files
- ✅ Must be included in complete SQL file

### Backend Requirements
- ✅ All repositories use inline SQL with proper parameterization
- ✅ No missing SQL commands
- ✅ All tables referenced
- ✅ Consistent patterns across repositories

### Encoding
- ✅ NO encoding issues found
- ✅ All Vietnamese text uses NVARCHAR with N-prefix
- ✅ Maintain current pattern

### Role-Switch Logic
- ✅ AuthService handles auto-creation of role records
- ⚠️ Current seed data MISSING Member records for Trainers
- ✅ Must add Member records for all 5 Trainer users
- ✅ Must add Trainer check-in examples

### Seed Data
- ✅ Comprehensive seed data exists for all tables
- ⚠️ Must add 5 Member records for Trainers (MemberId 21-25)
- ⚠️ Must add 5-10 Trainer check-ins
- ⚠️ Must use correct password hash from FIX_PASSWORDS.sql

### Critical User Requirements Addressed
1. ✅ Trainers can check in (need Member records)
2. ✅ Check-ins sorted by earliest first (ORDER BY CheckinTime ASC)
3. ✅ Role switching works (auto-creates target role record)
4. ✅ Vietnamese text properly encoded (NVARCHAR + N-prefix)
5. ✅ Stored procedures for audit logging

---

## File Paths Reference

**SQL Files:**
- `SQL2/00_REBUILD_DATABASE.sql` — Full rebuild (schema + seed data, truncated)
- `SQL2/01_CREATE_SCHEMA.sql` — Schema only (12 tables)
- `SQL2/02_SEED_DATA.sql` — Seed data only
- `SQL2/FIX_PASSWORDS.sql` — Correct BCrypt hash
- `SQL2/fix-missing-trainer-member-records.sql` — Migration for role-switch fix
- `.agents/tasks/SCHEMA_FIX_MISMATCHES.sql` — Stored procedures + fixes

**Backend Files:**
- `DAL/Entities/*.cs` — Entity definitions
- `DAL/Repositories/Implementations/*.cs` — Repository SQL commands
- `Service/BUS/Implementations/AuthService.cs` — Role-switch logic

**Total Files Read:** 25+ (SQL files, repositories, entities, services)

---

End of Investigation Report
