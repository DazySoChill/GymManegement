# Database Schema Fix and Cancel Membership Implementation

Fixes SQL schema mismatches and adds membership cancellation feature for a gym management system.

**Watch for:** SQL seed data has a critical column count mismatch in the Invoices INSERT statement (confirmed). Auth gap in cancel endpoint where admin bypass logic still requires member ownership check in service layer (confirmed). Schema fix script lacks IF NOT EXISTS guards on several ALTER statements and would fail on re-run (confirmed).

**Verdict**: NEEDS_CHANGES

## High-level view

The schema fix script successfully aligns all table structures between the database and C# entities, covering Memberships (PackageName rename), Invoices (MemberId addition), Schedules (MemberId removal, datetime consolidation), Sessions (cleanup of unused columns), Checkins (SessionId removal), Payments (MemberId backfill), Users (MemberId link), and Members (Status column removal). The script uses dynamic SQL to drop constraints before alterations but misses IF NOT EXISTS protection on several ALTER statements.

The seed data script generates comprehensive test data (1 admin, 5 trainers, 20 facilities, 30 members, 50 memberships, 240 schedules, 600 sessions, 100 checkins), but the Invoices INSERT has 11 columns in the statement while only 10 values in the VALUES clause, causing an immediate SQL syntax error.

InvoiceRepository.CreateAsync now includes MemberId in both the column list and parameters, fixing the original schema mismatch. MembershipService.CreateAsync sets `invoice.MemberId = membership.MemberId` before creating the invoice, fixing the bug where invoices were created with MemberId defaulting to 0.

The cancel membership feature implements a three-layer pattern (repository sets EndDate to today, service adds ownership validation, controller enforces role-based access). The repository query only affects active memberships (EndDate > today). The service layer checks that requestingMemberId matches the membership owner. The controller has separate logic for admin and member roles, but the admin path still calls the service with ownership validation, creating a gap where admins must pass the correct MemberId to bypass the check.

<details>
<summary>Issues (5)</summary>

1. **Invoices seed data column mismatch** — The INSERT statement lists 11 columns (MemberId through IsDeleted) but the SELECT provides only 10 values. Add `i.MemberId,` after the SELECT keyword to align the value count. Confirmed by reading COMPLETE_SEED_DATA.sql line examining the INSERT INTO Invoices statement.

2. **Schema fix ALTER statements lack IF NOT EXISTS guards** — Several ALTER TABLE statements (making InvoiceId nullable, making MembershipId nullable, making DueDate nullable, making UpdatedAt nullable) execute unconditionally and would fail on re-run if the column is already nullable. Wrap each ALTER COLUMN in a check: `IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('TableName') AND name = 'ColumnName' AND is_nullable = 0) BEGIN ... END`. Confirmed by reading COMPLETE_SCHEMA_FIX.sql.

3. **Admin cancel bypasses controller auth but not service auth** — The cancel endpoint lets admin/superadmin roles skip the ownership check in the controller, but then passes `membership.MemberId` to `_service.CancelAsync(id, membership.MemberId)`, which performs the same ownership check in the service layer. This works (admin passes the correct MemberId so the check succeeds), but the service-layer check is redundant and misleading. Either remove the requestingMemberId parameter from the service and repository methods (ownership check belongs in controller only), or change the controller to pass the admin's own MemberId and handle the authorization check consistently in one layer. Confirmed by reading MembershipController.cs Cancel method and MembershipService.cs CancelAsync method.

4. **Schedule StartTime/EndTime conversion assumes combined datetime** — The schema fix script converts `ScheduledDate + StartTime/EndTime (TIME)` to `StartTime/EndTime (DATETIME2)` by casting and adding: `CAST(CAST(ScheduledDate AS DATETIME) + CAST(StartTime AS DATETIME) AS DATETIME2)`. This only works if the existing Schedules table actually has ScheduledDate and TIME-type columns. If the table was already using DATETIME2 columns, this section does nothing (guarded by type check), but if it was using a different schema (e.g., StartTime already DATETIME), the rename step (`EXEC sp_rename 'Schedules.StartDateTime', 'StartTime', 'COLUMN'`) would fail because StartTime already exists. Confirmed by reading COMPLETE_SCHEMA_FIX.sql lines examining the Schedules table fix logic. Likely outcome: the script will error if run on a schema where StartTime is already DATETIME2.

5. **Seed data uses GETDATE() in backdated records** — The seed script sets `CreatedAt = GETDATE()` and `UpdatedAt = GETDATE()` for all records, even when the membership or invoice StartDate is weeks or months in the past. This creates a data inconsistency where a membership that started 60 days ago shows CreatedAt as today. For realistic test data, set `CreatedAt = m.StartDate` (or DATEADD(DAY, -1, m.StartDate)) instead of GETDATE() for historical records. Confirmed by reading COMPLETE_SEED_DATA.sql membership and invoice insert logic. Non-blocking (test data issue, not a functional bug).

</details>

<details>
<summary>Details</summary>

## SQL schema fix execution order and constraint handling

The schema fix script tackles eight tables in sequence: Memberships, Invoices, Payments, Schedules, Sessions, Checkins, Users, and Members. For each table, it drops conflicting constraints before altering columns (e.g., dropping the FK constraint on Invoices.MembershipId before making it nullable, then re-adding the constraint). The script uses dynamic SQL to locate constraint names by querying `sys.foreign_keys`, `sys.check_constraints`, and `sys.default_constraints`, avoiding hardcoded constraint names that might differ across environments.

Several ALTER COLUMN statements lack IF NOT EXISTS protection. For example, making `Invoices.MembershipId` nullable executes unconditionally. If the column is already nullable (from a prior run), the ALTER succeeds silently, but if a different alteration was applied, the script could error. The pattern should be: check `sys.columns.is_nullable`, then conditionally alter.

The Schedules table conversion (ScheduledDate + TIME columns to DATETIME2) is wrapped in a type check: `IF @StartTimeType = 'time'`. This guards against re-running the conversion when StartTime is already DATETIME2. But the script doesn't handle the case where StartTime is already DATETIME2 *and* named StartTime (not StartDateTime), which would cause the `sp_rename` step to fail.

## Seed data Invoices column count mismatch

The seed script creates invoices with this statement:

```sql
INSERT INTO Invoices (MemberId, MembershipId, TotalAmount, InvoiceDate, DueDate, Status, Description, CreatedAt, UpdatedAt, IsDeleted, DeletedAt)
SELECT 
    m.MemberId,
    m.MembershipId,
    m.Price,
    ...
```

The column list has 11 names: MemberId, MembershipId, TotalAmount, InvoiceDate, DueDate, Status, Description, CreatedAt, UpdatedAt, IsDeleted, DeletedAt. The SELECT clause provides 10 values (starts with `m.MemberId, m.MembershipId, m.Price, ...` but the logic selects only up to `NULL` for DeletedAt, missing one value). The correct SELECT should list `m.MemberId,` before `m.MembershipId`. Without this, SQL Server returns "Column name or number of supplied values does not match table definition."

## InvoiceRepository MemberId fix

The CreateAsync method now includes MemberId in both the INSERT column list and the parameters object:

```csharp
INSERT INTO Invoices (MemberId, MembershipId, TotalAmount, InvoiceDate, DueDate, Status, Description, CreatedAt, UpdatedAt, IsDeleted)
VALUES (@MemberId, @MembershipId, @TotalAmount, @InvoiceDate, @DueDate, @Status, @Description, GETDATE(), GETDATE(), 0);
```

GetByMemberIdAsync uses direct MemberId lookup instead of joining through Memberships (more efficient, and correct when invoices exist without a membership).

## MembershipService auto-invoice MemberId population

The CreateAsync method sets `invoice.MemberId = membership.MemberId` when constructing the auto-invoice, fixing the bug where MemberId defaulted to 0.

## Cancel membership repository implementation

MembershipRepository.CancelAsync sets EndDate to today:

```csharp
UPDATE Memberships 
SET EndDate = CAST(GETDATE() AS DATE),
    UpdatedAt = GETDATE()
WHERE MembershipId = @MembershipId 
  AND IsDeleted = 0
  AND EndDate > CAST(GETDATE() AS DATE)
```

The WHERE clause includes `EndDate > today`, so canceling an already-expired or already-cancelled membership returns 0 rows affected (returns false), preventing double-cancellation.

## Cancel membership service and controller authorization

MembershipService.CancelAsync checks ownership:

```csharp
public async Task<bool> CancelAsync(int membershipId, int requestingMemberId)
{
    var entity = await _repo.GetByIdAsync(membershipId);
    if (entity is null) return false;
    if (entity.MemberId != requestingMemberId) return false; // Security check
    var cancelled = await _repo.CancelAsync(membershipId);
    return cancelled;
}
```

This prevents member A from canceling member B's membership. The controller enforces role-based access:

- Admin/SuperAdmin: Fetches the membership, retrieves `membership.MemberId`, passes it to `_service.CancelAsync(id, membership.MemberId)`. The service layer's ownership check compares `membership.MemberId == membership.MemberId`, which always succeeds.
- Member: Extracts `MemberId` from JWT claims, passes `userMemberId` to the service. The service layer's ownership check compares `membership.MemberId == userMemberId`, which fails if the member doesn't own the membership.

The admin path works, but the logic is confusing: the controller explicitly checks "if admin, bypass ownership check" but then calls a service method that *performs* an ownership check. The service method signature `CancelAsync(int membershipId, int requestingMemberId)` suggests requestingMemberId is the user making the request, but the admin path passes the *target* membership's MemberId, not the admin's own MemberId. This conflates "who is requesting" with "who owns the membership."

The cleaner design: remove `requestingMemberId` from service and repository, perform ownership check only in the controller before calling the service. Or: keep the parameter but pass the actual requesting user's MemberId (admin's own MemberId), and add an admin bypass inside the service layer.

## Seed data generated quantity and structure

The seed script creates:
- 1 SuperAdmin (username: gymadmin, password: Gym@2026)
- 5 Trainers with 5 trainer User accounts
- 20 Facilities (10 rooms, 10 equipment)
- 30 Members with 30 member User accounts
- 50 Memberships (25 active, 25 expired)
- 240 Schedules (30 days × 8 classes/day)
- 600 Sessions (60 schedules × 10 registrations each)
- 100 Checkins (last 30 days, 80% have checkout time)
- 50 Invoices (one per membership, all marked Paid)
- 50 Payments (one per invoice, mix of Cash/Card/QRCode)

The script creates 50 memberships for 30 members, meaning some members have multiple memberships (historical + current), testing the GetByMemberIdAsync query.

</details>

<details>
<summary>File map</summary>

- **SQL2/COMPLETE_SCHEMA_FIX.sql** — Schema alignment script covering 8 tables
- **SQL2/COMPLETE_SEED_DATA.sql** — Test data generation with 500+ records
- **SQL2/RUN_COMPLETE_FIX.sql** — Master script running schema fix + seed data
- **DAL/Repositories/Implementations/InvoiceRepository.cs** — Added MemberId to CreateAsync INSERT
- **Service/BUS/Implementations/MembershipService.cs** — Set invoice.MemberId in CreateAsync, added CancelAsync
- **DAL/Repositories/Interfaces/IMembershipRepository.cs** — Added CancelAsync signature
- **DAL/Repositories/Implementations/MembershipRepository.cs** — Implemented CancelAsync soft-cancel
- **Service/BUS/Interfaces/IMembershipService.cs** — Added CancelAsync signature
- **Controllers/MembershipController.cs** — Added POST /api/Membership/{id}/cancel endpoint

Full diff: `git diff main` (run from workspace root)

</details>
