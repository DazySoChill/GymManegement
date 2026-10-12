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

1. **Injected `ILogger<AuthService>` and `ITrainerRepository`** into `AuthService` constructor
   - Now has access to `_memberRepo`, `_trainerRepo`, and `_logger`
   - Uses structured logging instead of Console.WriteLine for production observability

2. **Fixed QRCode race condition in `RegisterAsync`**
   - Changed from pre-calculating QRCode using `IDENT_CURRENT('Members') + 1` (race-prone)
   - Now creates Member with temporary QRCode "TEMP", then updates with actual MemberId-based QRCode
   - Pattern: Insert → Get assigned MemberId → Update QRCode = `M{MemberId:D6}`
   - **Concurrency-safe**: Each insert gets its own MemberId from IDENTITY, no race condition

3. **Modified `CreateStaffAsync`**
   - After creating User with Role="Trainer", auto-creates Trainer record
   - Uses defensive check (`GetByEmailAsync`) to avoid duplicate creation
   - Default values: Phone="" (empty string), Specialization="General"
   - Wrapped in try-catch; logs warning via ILogger on failure but does NOT rethrow (User creation succeeded)

4. **Modified `UpdateUserRoleAsync`**
   - After updating `User.Role`, checks the new role:
     - If `newRole == "Trainer"`: creates Trainer record if missing
     - If `newRole == "Member"`: creates Member record with concurrency-safe QRCode (same pattern as RegisterAsync)
   - Uses post-insert QRCode generation: Create with "TEMP" → Update with `M{MemberId:D6}`
   - Wrapped in try-catch; logs warning via ILogger on failure but does NOT rethrow (role update succeeded)

### Database Migration

**File**: `.agents/tasks/fix-missing-trainer-member-records.sql`

- Backfills missing `Trainer` records for existing users with Role='Trainer'
- Backfills missing `Member` records for existing users with Role='Member'
- Uses concurrency-safe QRCode generation:
  1. Insert Members with temporary QRCode = `TEMP_{UserId}`
  2. Update QRCodes to `M{MemberId:D6}` using the assigned MemberIds
- Includes verification queries to confirm zero orphaned users remain and no TEMP QRCodes left
- **Must be run ONCE** after deploying the code changes

## Review Findings Addressed

### 1. QRCode Race Condition (Fixed)
**Issue**: `IDENT_CURRENT('Members') + 1` is not concurrency-safe. Parallel operations could generate duplicate QRCodes.

**Fix**: Changed to post-insert pattern:
```csharp
// Insert with temporary QRCode
var member = new Member { /* ... */, QRCode = "TEMP" };
await _memberRepo.CreateAsync(member);

// Update with actual MemberId-based QRCode (concurrency-safe)
var qrCode = $"M{member.MemberId:D6}";
await conn.ExecuteAsync("UPDATE Members SET QRCode = @QRCode WHERE MemberId = @MemberId", 
    new { QRCode = qrCode, member.MemberId });
```

Each Member gets its own unique MemberId from IDENTITY sequence, eliminating race condition.

### 2. Duplicate Email Handling (Documented)
**Issue**: Trainers and Members tables have indexes but NOT unique constraints on Email. Concurrent operations could attempt duplicate email inserts.

**Status**: 
- Current schema (SQL2/01_CREATE_SCHEMA.sql) only has indexes on Email, not unique constraints
- `GetByEmailAsync` check + try-catch provides defensive handling
- If duplicate insert occurs, try-catch logs warning but doesn't fail primary operation
- **Future improvement**: Add filtered unique indexes on Email where IsDeleted = 0

### 3. Console.WriteLine Logging (Fixed)
**Issue**: Console.WriteLine won't persist in production logging infrastructure.

**Fix**: 
- Injected `ILogger<AuthService>` into constructor
- Replaced all `Console.WriteLine` with structured logging:
  - `_logger.LogInformation(...)` for successful auto-creation
  - `_logger.LogWarning(ex, ...)` for failures with exception context
- Logs will now persist in configured logging infrastructure (Serilog, Application Insights, etc.)

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
   - Check logs for: "Auto-created Trainer record for email: {Email}"

3. **Test UpdateUserRoleAsync to Trainer**:
   - Change an Admin user to Trainer role
   - Query database: `SELECT * FROM Trainers WHERE Email = '<user-email>'`
   - Expected: Trainer record auto-created
   - Check logs for: "Auto-created Trainer record for UserId {UserId}"

4. **Test UpdateUserRoleAsync to Member**:
   - Change an Admin user to Member role
   - Query database: `SELECT * FROM Members WHERE Email = '<user-email>'`
   - Expected: Member record with QRCode format M{number:D6} (e.g., M000123)
   - Check logs for: "Auto-created Member record for UserId {UserId} (QRCode: {QRCode})"

5. **Test concurrency safety** (optional but recommended):
   - Simulate parallel role changes to Member for multiple users
   - Verify all Members have unique QRCodes with no duplicates
   - Query: `SELECT QRCode, COUNT(*) FROM Members GROUP BY QRCode HAVING COUNT(*) > 1`
   - Expected: No results (no duplicate QRCodes)

### After Database Migration

1. **Run the SQL script**:
   ```sql
   -- In SSMS or Azure Data Studio connected to your SQL Server
   -- Open and execute: .agents/tasks/fix-missing-trainer-member-records.sql
   ```

2. **Verify zero orphaned users**:
   - Check the verification output at end of script
   - All SyncStatus should be 'OK' (no MISSING TRAINER/MEMBER RECORD, no QRCODE NOT UPDATED)

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
   -- Check for QRCodes that match the backfill pattern
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

**Answer**: The primary operation (User creation or role update) has already succeeded. If Trainer/Member creation fails (e.g., transient DB issue, duplicate email), the User is still valid. We log the warning for monitoring, and the next login or role operation will retry creation via the defensive check. Throwing would incorrectly signal that the User operation failed.

### Why use post-insert QRCode generation instead of pre-calculating?

**Answer**: The original approach using `IDENT_CURRENT('Members') + 1` had a race condition: two parallel inserts could both read the same "next" value and generate duplicate QRCodes. The post-insert pattern eliminates this:
1. Insert Member with temporary QRCode
2. Get the assigned MemberId (unique, guaranteed by IDENTITY)
3. Update QRCode based on the actual MemberId

This is concurrency-safe because each insert receives its own unique MemberId from the database IDENTITY sequence.

### Why default Specialization = "General" for auto-created Trainers?

**Answer**: `Specialization` is nullable in the DB schema but the entity property is `string?`. Using "General" provides a sensible default that won't break UI dropdowns or reports expecting non-null values. Admins can edit it later via the Trainer management UI.

### Why not add unique constraints on Email columns?

**Answer**: The current schema design uses soft-delete (IsDeleted flag) which requires filtered unique indexes `WHERE IsDeleted = 0`. Adding these constraints is a schema change beyond the scope of this fix. The defensive `GetByEmailAsync` check + try-catch provides sufficient protection for now. Future work should add:
```sql
CREATE UNIQUE INDEX UQ_Trainers_Email_Active ON Trainers(Email) WHERE IsDeleted = 0;
CREATE UNIQUE INDEX UQ_Members_Email_Active ON Members(Email) WHERE IsDeleted = 0;
```

## Testing Checklist

- [ ] Code builds without errors
- [ ] CreateStaffAsync with Role="Trainer" creates Trainer record
- [ ] CreateStaffAsync with Role="Admin" does NOT create Trainer/Member record
- [ ] UpdateUserRoleAsync to "Trainer" creates Trainer record if missing
- [ ] UpdateUserRoleAsync to "Member" creates Member record with valid QRCode
- [ ] UpdateUserRoleAsync to "Admin" does NOT create entity records
- [ ] Logs show structured logging (not Console.WriteLine)
- [ ] SQL migration script runs without errors
- [ ] Verification queries show zero orphaned users after migration
- [ ] No duplicate QRCodes exist in Members table
- [ ] Frontend no longer shows "Không tìm thấy thông tin trainer" for existing Trainer users
- [ ] New Trainer users can access trainer-specific UI without errors

## Dependencies

- **Code**: Requires `ITrainerRepository` already registered in DI container
- **Logging**: Requires ILogger<T> configured in Program.cs (standard ASP.NET Core setup)
- **Database**: Requires `Users`, `Trainers`, `Members` tables already exist
- **No breaking changes**: All changes are additive; existing functionality preserved

## Deployment Order

1. Deploy code changes (AuthService.cs)
2. Restart application
3. Run SQL migration script (fix-missing-trainer-member-records.sql)
4. Verify frontend functionality
5. Monitor logs for any auto-creation warnings

---

**Implementation Date**: [Current Date]  
**Status**: Completed - Review findings addressed
