# Implementation Plan: Fix Missing Trainer/Member Records on User Role Assignment

## Context

**Problem**: When creating staff users (Admin/Trainer) via `CreateStaffAsync` or changing roles via `UpdateUserRoleAsync`, the system creates only the `Users` record but does NOT create corresponding `Trainer` or `Member` records. This causes "Không tìm thấy thông tin trainer" errors when the frontend expects these records to exist.

**Root Cause**:
- `RegisterAsync` correctly auto-creates `Member` record with sequential QRCode (format: M000001, M000002, etc.)
- `CreateStaffAsync` creates only `User` record — missing `Trainer` creation for Trainer role
- `UpdateUserRoleAsync` updates `User.Role` but never creates the corresponding entity record

**Solution**: Auto-create `Trainer` or `Member` records whenever a User is assigned those roles, matching the pattern already working in `RegisterAsync`.

---

## Implementation Steps

### Step 1: Inject ITrainerRepository into AuthService

Modify `Service/BUS/Implementations/AuthService.cs` constructor to inject `ITrainerRepository`.

**What to do**:
- Add `private readonly ITrainerRepository _trainerRepo;` field to `AuthService` class
- Add `ITrainerRepository trainerRepo` parameter to constructor
- Assign `_trainerRepo = trainerRepo;` in constructor body
- Remove duplicate `_memberRepo` and `_config` assignments in constructor (lines 20-21 currently duplicate lines 18-19)

**Files**:
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Implementations\AuthService.cs`

**Verify**: 
Run `dotnet build --no-restore` and confirm no compilation errors. Expected output: "Build succeeded."

---

### Step 2: Auto-create Trainer record in CreateStaffAsync when Role is Trainer

Modify `CreateStaffAsync` method in `AuthService.cs` to create a `Trainer` record after creating the `User` if `request.Role == "Trainer"`.

**What to do**:
- After the line `await _userRepo.CreateAsync(user, request.Password);` (currently line 115)
- Add conditional logic:
  ```csharp
  // Auto-create Trainer record if role is Trainer
  if (request.Role == "Trainer")
  {
      try
      {
          // Check if Trainer record already exists (defensive)
          var existingTrainer = await _trainerRepo.GetByEmailAsync(user.Email);
          if (existingTrainer is null)
          {
              var trainer = new Trainer
              {
                  FullName = user.FullName,
                  Email = user.Email,
                  Phone = "", // Empty string (Phone is nullable but prefer empty)
                  Specialization = "General" // Default specialization
              };
              await _trainerRepo.CreateAsync(trainer);
              _logger.LogInformation("Auto-created Trainer record for email: {Email}", user.Email);
          }
      }
      catch (Exception ex)
      {
          // Log warning but do NOT rethrow (User creation already succeeded)
          _logger.LogWarning(ex, "Failed to auto-create Trainer record for {Email}. User was created successfully.", user.Email);
      }
  }
  ```
- Add `using GymManegement.DAL.Entities;` at top of file if not already present

**Files**:
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Implementations\AuthService.cs`

**Verify**: 
Run `dotnet build --no-restore` and confirm no compilation errors. Test manually: use Swagger or Postman to call `/api/auth/staff` with Role="Trainer", then query `Trainers` table to confirm the record was created.

---

### Step 3: Auto-create Trainer or Member record in UpdateUserRoleAsync

Modify `UpdateUserRoleAsync` method in `AuthService.cs` to create corresponding `Trainer` or `Member` records when changing roles.

**What to do**:
- After `await _userRepo.UpdateAsync(user);` (currently line 139)
- Add role-specific entity creation logic:
  ```csharp
  // Auto-create corresponding entity record for new role
  try
  {
      if (newRole == "Trainer")
      {
          var existingTrainer = await _trainerRepo.GetByEmailAsync(user.Email);
          if (existingTrainer is null)
          {
              var trainer = new Trainer
              {
                  FullName = user.FullName,
                  Email = user.Email,
                  Phone = "",
                  Specialization = "General"
              };
              await _trainerRepo.CreateAsync(trainer);
              _logger.LogInformation("Auto-created Trainer record for UserId {UserId} (email: {Email})", userId, user.Email);
          }
      }
      else if (newRole == "Member")
      {
          var existingMember = await _memberRepo.GetByEmailAsync(user.Email);
          if (existingMember is null)
          {
              // Generate sequential QRCode (same pattern as RegisterAsync)
              using var conn = _db.CreateConnection();
              var nextMemberId = await conn.ExecuteScalarAsync<int>(
                  "SELECT ISNULL(IDENT_CURRENT('Members'), 0) + 1");
              var qrCode = $"M{nextMemberId:D6}";
              
              var member = new Member
              {
                  FullName = user.FullName,
                  Email = user.Email,
                  Phone = null,
                  DateOfBirth = null,
                  QRCode = qrCode
              };
              await _memberRepo.CreateAsync(member);
              _logger.LogInformation("Auto-created Member record for UserId {UserId} (email: {Email}, QRCode: {QRCode})", userId, user.Email, qrCode);
          }
      }
  }
  catch (Exception ex)
  {
      _logger.LogWarning(ex, "Failed to auto-create entity record for UserId {UserId} with role {Role}. Role update succeeded.", userId, newRole);
  }
  ```
- This matches the QRCode generation pattern from `RegisterAsync` (lines 69-71) exactly

**Files**:
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Implementations\AuthService.cs`

**Verify**: 
Run `dotnet build --no-restore` and confirm no compilation errors. Test: change a user's role from Admin → Trainer, verify Trainer record created; change another from Admin → Member, verify Member record with QRCode created.

---

### Step 4: Create SQL migration script for existing orphaned users

Create a SQL script to backfill missing `Trainer` and `Member` records for existing users in the database.

**What to do**:
- Create file `d:\Workspace\Độ án 2\GymManegement\GymManegement\.agents\tasks\fix-missing-trainer-member-records.sql`
- Script must:
  1. Insert missing `Trainer` records for users with Role='Trainer' who lack a Trainer record
  2. Insert missing `Member` records for users with Role='Member' who lack a Member record, with auto-generated sequential QRCodes
  3. Include SELECT statements at the end to verify the fix

**Content**:
```sql
-- ========================================
-- Backfill missing Trainer and Member records
-- Run this ONCE after deploying the code fix
-- ========================================

USE GymDb;
GO

PRINT 'Starting backfill of missing Trainer and Member records...';
GO

-- ========================================
-- 1. Create missing Trainer records
-- ========================================

PRINT 'Inserting missing Trainer records...';

INSERT INTO Trainers (FullName, Email, Phone, Specialization, CreatedAt, UpdatedAt, IsDeleted)
SELECT 
    u.FullName,
    u.Email,
    '' AS Phone,  -- Empty string (Phone is nullable but consistent with code default)
    'General' AS Specialization,  -- Default specialization
    GETDATE() AS CreatedAt,
    GETDATE() AS UpdatedAt,
    0 AS IsDeleted
FROM Users u
WHERE u.Role = 'Trainer'
  AND u.IsActive = 1
  AND NOT EXISTS (
      SELECT 1 FROM Trainers t 
      WHERE t.Email = u.Email AND t.IsDeleted = 0
  );

DECLARE @TrainerCount INT = @@ROWCOUNT;
PRINT CONCAT('Created ', @TrainerCount, ' missing Trainer records.');
GO

-- ========================================
-- 2. Create missing Member records with sequential QRCodes
-- ========================================

PRINT 'Inserting missing Member records...';

-- Get the next available MemberId for QRCode generation
DECLARE @NextMemberId INT = ISNULL(IDENT_CURRENT('Members'), 0) + 1;

-- Insert missing Member records
INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode, CreatedAt, UpdatedAt, IsDeleted)
SELECT 
    u.FullName,
    u.Email,
    NULL AS Phone,
    NULL AS DateOfBirth,
    -- Generate sequential QRCode: M000001, M000002, etc.
    'M' + RIGHT('000000' + CAST(ROW_NUMBER() OVER (ORDER BY u.UserId) + @NextMemberId - 1 AS VARCHAR), 6) AS QRCode,
    GETDATE() AS CreatedAt,
    GETDATE() AS UpdatedAt,
    0 AS IsDeleted
FROM Users u
WHERE u.Role = 'Member'
  AND u.IsActive = 1
  AND NOT EXISTS (
      SELECT 1 FROM Members m 
      WHERE m.Email = u.Email AND m.IsDeleted = 0
  );

DECLARE @MemberCount INT = @@ROWCOUNT;
PRINT CONCAT('Created ', @MemberCount, ' missing Member records.');
GO

-- ========================================
-- 3. Verification queries
-- ========================================

PRINT '';
PRINT '========================================';
PRINT 'VERIFICATION RESULTS';
PRINT '========================================';

-- Check for remaining orphaned Trainer users
SELECT 
    'Remaining orphaned Trainer users' AS CheckType,
    COUNT(*) AS Count
FROM Users u
WHERE u.Role = 'Trainer'
  AND u.IsActive = 1
  AND NOT EXISTS (SELECT 1 FROM Trainers t WHERE t.Email = u.Email AND t.IsDeleted = 0);

-- Check for remaining orphaned Member users
SELECT 
    'Remaining orphaned Member users' AS CheckType,
    COUNT(*) AS Count
FROM Users u
WHERE u.Role = 'Member'
  AND u.IsActive = 1
  AND NOT EXISTS (SELECT 1 FROM Members m WHERE m.Email = u.Email AND m.IsDeleted = 0);

-- Show sample of newly created Trainer records
PRINT '';
PRINT 'Sample of Trainer records (top 5):';
SELECT TOP 5 TrainerId, FullName, Email, Specialization, CreatedAt
FROM Trainers
WHERE IsDeleted = 0
ORDER BY CreatedAt DESC;

-- Show sample of newly created Member records with QRCodes
PRINT '';
PRINT 'Sample of Member records (top 5):';
SELECT TOP 5 MemberId, FullName, Email, QRCode, CreatedAt
FROM Members
WHERE IsDeleted = 0
ORDER BY CreatedAt DESC;

PRINT '';
PRINT '========================================';
PRINT 'Backfill complete. Check counts above.';
PRINT 'Expected: Both orphaned counts should be 0.';
PRINT '========================================';
GO
```

**Files**:
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\.agents\tasks\fix-missing-trainer-member-records.sql` (create new)

**Verify**: 
Read the file content and confirm SQL syntax is correct. DO NOT execute it yet — this is for the database administrator to run manually after code deployment.

---

### Step 5: Create implementation documentation

Create a documentation file explaining the changes, rationale, usage, and rollback plan.

**What to do**:
- Create file `d:\Workspace\Độ án 2\GymManegement\GymManegement\.agents\tasks\user-trainer-member-sync-implementation.md`

**Content**:
```markdown
# User-Trainer-Member Sync Implementation

## Problem Summary

Users with role "Trainer" or "Member" (created via `CreateStaffAsync` or `UpdateUserRoleAsync`) were missing corresponding records in the `Trainers` or `Members` tables. This caused frontend errors like "Không tìm thấy thông tin trainer" when the UI expected these records to exist.

## Root Cause

- **RegisterAsync**: ✅ Correctly creates both `User` (role=Member) AND `Member` record with sequential QRCode
- **CreateStaffAsync**: ❌ Only creates `User` record — missing `Trainer` creation for Trainer role
- **UpdateUserRoleAsync**: ❌ Only updates `User.Role` — never creates corresponding entity records

## Solution Implemented

### Code Changes

**File**: `Service/BUS/Implementations/AuthService.cs`

1. **Injected `ITrainerRepository`** into `AuthService` constructor
   - Now has access to both `_memberRepo` and `_trainerRepo`

2. **Modified `CreateStaffAsync`**
   - After creating User with Role="Trainer", auto-creates Trainer record
   - Uses defensive check (`GetByEmailAsync`) to avoid duplicate creation
   - Default values: Phone="" (empty string), Specialization="General"
   - Wrapped in try-catch; logs warning on failure but does NOT rethrow (User creation succeeded)

3. **Modified `UpdateUserRoleAsync`**
   - After updating `User.Role`, checks the new role:
     - If `newRole == "Trainer"`: creates Trainer record if missing
     - If `newRole == "Member"`: creates Member record if missing (with sequential QRCode matching RegisterAsync pattern)
   - Uses `IDENT_CURRENT('Members')` to generate next QRCode: `M{nextId:D6}`
   - Wrapped in try-catch; logs warning on failure but does NOT rethrow (role update succeeded)

### Database Migration

**File**: `.agents/tasks/fix-missing-trainer-member-records.sql`

- Backfills missing `Trainer` records for existing users with Role='Trainer'
- Backfills missing `Member` records for existing users with Role='Member' with auto-generated QRCodes
- Includes verification queries to confirm zero orphaned users remain
- **Must be run ONCE** after deploying the code changes

## Verification Steps

### After Code Deployment

1. **Build verification**:
   ```bash
   dotnet build --no-restore
   ```
   Expected: "Build succeeded. 0 Error(s)"

2. **Test CreateStaffAsync with Trainer role**:
   - Use Swagger UI: POST `/api/auth/staff` with Role="Trainer"
   - Query database: `SELECT * FROM Trainers WHERE Email = '<new-email>'`
   - Expected: Trainer record exists with FullName, Email, Phone="", Specialization="General"

3. **Test UpdateUserRoleAsync to Trainer**:
   - Change an Admin user to Trainer role
   - Query database: `SELECT * FROM Trainers WHERE Email = '<user-email>'`
   - Expected: Trainer record auto-created

4. **Test UpdateUserRoleAsync to Member**:
   - Change an Admin user to Member role
   - Query database: `SELECT * FROM Members WHERE Email = '<user-email>'`
   - Expected: Member record with QRCode format M{number:D6}

### After Database Migration

1. **Run the SQL script**:
   ```sql
   -- In SSMS or Azure Data Studio connected to your SQL Server
   -- Open and execute: .agents/tasks/fix-missing-trainer-member-records.sql
   ```

2. **Verify zero orphaned users**:
   - Check the verification output at end of script
   - Both "Remaining orphaned Trainer users" and "Remaining orphaned Member users" counts should be 0

3. **Frontend verification**:
   - Log in as a Trainer user who previously had no Trainer record
   - Navigate to trainer-specific pages (e.g., Lịch Class)
   - Expected: No more "Không tìm thấy thông tin trainer" errors

## Rollback Plan

If issues arise:

1. **Code rollback**:
   ```bash
   git revert <commit-hash>
   dotnet build
   # Restart the application
   ```

2. **Database rollback** (if you need to remove backfilled records):
   ```sql
   -- Remove backfilled Trainer records (created by migration)
   DELETE FROM Trainers 
   WHERE Specialization = 'General' 
     AND Phone = ''
     AND CreatedAt > '<migration-run-timestamp>';
   
   -- Remove backfilled Member records (created by migration)
   DELETE FROM Members 
   WHERE Phone IS NULL 
     AND DateOfBirth IS NULL
     AND CreatedAt > '<migration-run-timestamp>';
   ```
   **⚠️ WARNING**: This is destructive. Only run if absolutely necessary.

## Design Decisions

### Why inject ITrainerRepository instead of ITrainerService?

**Answer**: `TrainerService.CreateAsync` throws `InvalidOperationException` if email already exists. In `AuthService`, we want to check-then-create defensively (using `GetByEmailAsync` + conditional create), not rely on exception handling. Direct repository access gives us that control.

### Why log warning but not rethrow on entity creation failure?

**Answer**: The primary operation (User creation or role update) has already succeeded. If Trainer/Member creation fails (e.g., transient DB issue), the User is still valid. We log the warning for monitoring, and the next login or role operation will retry creation via the defensive check. Throwing would incorrectly signal that the User operation failed.

### Why use IDENT_CURRENT for QRCode generation?

**Answer**: Matches the existing pattern in `RegisterAsync` (lines 69-71). Sequential QRCodes (M000001, M000002, etc.) are a business requirement for member identification and check-in systems. Using IDENTITY value ensures uniqueness without additional locking.

### Why default Specialization = "General" for auto-created Trainers?

**Answer**: `Specialization` is nullable in the DB schema but the entity property is `string?`. Using "General" provides a sensible default that won't break UI dropdowns or reports expecting non-null values. Admins can edit it later via the Trainer management UI.

## Testing Checklist

- [ ] Code builds without errors
- [ ] CreateStaffAsync with Role="Trainer" creates Trainer record
- [ ] CreateStaffAsync with Role="Admin" does NOT create Trainer/Member record
- [ ] UpdateUserRoleAsync to "Trainer" creates Trainer record if missing
- [ ] UpdateUserRoleAsync to "Member" creates Member record with valid QRCode
- [ ] UpdateUserRoleAsync to "Admin" does NOT create entity records
- [ ] SQL migration script runs without errors
- [ ] Verification queries show zero orphaned users after migration
- [ ] Frontend no longer shows "Không tìm thấy thông tin trainer" for existing Trainer users
- [ ] New Trainer users can access trainer-specific UI without errors

## Dependencies

- **Code**: Requires `ITrainerRepository` already registered in DI container (✅ confirmed in `Program.cs` line 14)
- **Database**: Requires `Users`, `Trainers`, `Members` tables already exist (✅ confirmed in SQL2 schema)
- **No breaking changes**: All changes are additive; existing functionality preserved

## Deployment Order

1. Deploy code changes (AuthService.cs)
2. Restart application
3. Run SQL migration script (fix-missing-trainer-member-records.sql)
4. Verify frontend functionality

---

**Implementation Date**: TBD  
**Implemented By**: TBD  
**Reviewed By**: TBD  
**Status**: Ready for Implementation
```

**Files**:
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\.agents\tasks\user-trainer-member-sync-implementation.md` (create new)

**Verify**: 
Read the documentation and confirm it accurately describes the implementation, includes all necessary verification steps, and provides clear rollback instructions.

---

## Summary

This plan fixes the root cause of "Không tìm thấy thông tin trainer" errors by ensuring that whenever a User is assigned the "Trainer" or "Member" role, the corresponding entity record is automatically created. The implementation:

- ✅ Matches the existing pattern from `RegisterAsync` (auto-create Member with QRCode)
- ✅ Handles both new staff creation (`CreateStaffAsync`) and role changes (`UpdateUserRoleAsync`)
- ✅ Is defensive (checks for existing records before creating)
- ✅ Is resilient (logs warnings but doesn't fail the primary operation)
- ✅ Includes a migration script for existing orphaned users
- ✅ Provides comprehensive documentation and rollback plan

**Total files modified**: 1  
**Total files created**: 2  
**Build impact**: None (purely additive changes)  
**Runtime impact**: Minimal (one additional DB query + insert per role assignment)
