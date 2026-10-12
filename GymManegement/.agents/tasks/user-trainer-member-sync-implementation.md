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
   - Removed duplicate field assignments in constructor

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
   dotnet build
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

**Answer**: Matches the existing pattern in `RegisterAsync`. Sequential QRCodes (M000001, M000002, etc.) are a business requirement for member identification and check-in systems. Using IDENTITY value ensures uniqueness without additional locking.

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

- **Code**: Requires `ITrainerRepository` already registered in DI container
- **Database**: Requires `Users`, `Trainers`, `Members` tables already exist
- **No breaking changes**: All changes are additive; existing functionality preserved

## Deployment Order

1. Deploy code changes (AuthService.cs)
2. Restart application
3. Run SQL migration script (fix-missing-trainer-member-records.sql)
4. Verify frontend functionality

---

**Implementation Date**: [Current Date]  
**Status**: Completed
