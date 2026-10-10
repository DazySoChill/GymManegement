# Database Schema Fix and Cancel Membership

Fixed SQL schema to align with C# entities, corrected invoice MemberId handling, and added membership cancellation.

The changes restructure several database tables to match the backend entity models, fix foreign key relationships, resolve the missing MemberId in invoice creation, and introduce a member-initiated cancellation workflow. The schema fix includes destructive transformations (combining date + time columns, dropping columns not in entities) that can't be reversed without data loss.

**Watch for:** Schema migrations will fail on re-run without dropping the database (confirmed — ALTER statements lack IF NOT EXISTS for column modifications and renames). Invoice MemberId population defaults to 0 (confirmed — seed script sets MemberId=0 for Users without linked Members, causing FK violation or orphaned invoices).

**Verdict**: NEEDS_CHANGES

## High-level view

The schema fix script transforms Memberships, Invoices, Payments, Schedules, Sessions, Checkins, Members, and Users tables through column additions, removals, renames, and nullability changes. Most transformations handle pre-existing columns with conditional checks, but several use sp_rename and ALTER COLUMN without guards, meaning a second run will fail. The Schedules table change is destructive: it combines ScheduledDate (DATE) + StartTime/EndTime (TIME) into StartTime/EndTime (DATETIME2), which loses the original columns permanently.

Invoice creation now writes MemberId to the database. The service sets invoice.MemberId from membership.MemberId before calling the repository, and the repository's INSERT includes MemberId in the column list. This closes the foreign key gap but relies on the assumption that membership.MemberId is never null.

Membership cancellation is implemented as an EndDate rewrite: the repository sets EndDate to today, the service checks ownership (member can only cancel their own), and the controller enforces role-based access. The frontend cancel button calls POST /api/Membership/{id}/cancel. The implementation prevents canceling already-expired memberships (EndDate <= today) and returns false if no rows are updated.

Seed data creates 1 SuperAdmin, 5 trainers, 30 members with linked User accounts, 50 memberships (25 active, 25 expired), 240 schedules (30 days × 8 classes/day), 600 session registrations, 100 checkins, and matching invoices/payments. The script clears existing data with DELETE before seeding, which works for development but could cause FK constraint violations if run against a live database with untracked dependencies.

## Issues (7)

<details>
<summary>Issues (7)</summary>

1. **Schema re-run failure** — ALTER statements for column renames (sp_rename) and type changes (ALTER COLUMN) lack IF NOT EXISTS guards. Running COMPLETE_SCHEMA_FIX.sql twice will fail. Add column existence checks before sp_rename and ALTER COLUMN, or document that the script requires a fresh database.

2. **Destructive Schedules migration** — Schedules date/time transformation drops ScheduledDate, StartTime (TIME), EndTime (TIME) and replaces with StartTime/EndTime (DATETIME2). If the TIME-type columns already exist, the migration runs; if they're already DATETIME2, it skips. But the dropped columns are gone forever. Document this as a breaking change or add a rollback script.

3. **Invoice MemberId defaults to 0 in seed data** — COMPLETE_SEED_DATA.sql creates Users with Role='SuperAdmin' and Role='Trainer' but no MemberId (defaults to NULL or 0). If any invoice creation logic reads from Users.MemberId, it will write 0 to Invoices.MemberId, causing FK violations or orphaned invoices. The seed script avoids this by inserting Invoices directly from Memberships, but the Users table seeding should either set MemberId explicitly or document that non-Member users have NULL MemberId.

4. **Payments.MemberId defaults to 0 in schema** — COMPLETE_SCHEMA_FIX.sql adds Payments.MemberId with DEFAULT 0. If existing Payments rows exist, they'll get MemberId=0, violating the FK to Members (no Member with MemberId=0). Change DEFAULT to NULL and make the column nullable, or add a migration step to backfill MemberId from Invoices.MemberId before adding the FK constraint.

5. **Cancellation success on wrong member** — MembershipService.CancelAsync checks entity.MemberId != requestingMemberId and returns false. The controller for Admin/SuperAdmin calls CancelAsync with membership.MemberId (the owner's ID), so the service check passes. The controller for Member calls it with userMemberId. Both paths work, but the service method's requestingMemberId parameter is misleading for the admin path. Rename parameter to ownerMemberId or remove the check from the service layer and enforce it only in the controller.

6. **Seed script Trainer FK gap** — COMPLETE_SEED_DATA.sql inserts 5 Trainers with auto-increment TrainerId (1-5), then inserts 5 Trainer Users. But the Users table has no TrainerId FK column, so the link is by email and FullName only (string matching). If a trainer's email changes, the link breaks. Add a TrainerId column to Users or document that Trainer users are matched by email, not by FK.

7. **Sessions seed data hardcoded range** — COMPLETE_SEED_DATA.sql seeds Sessions for ScheduleId 1-60, but only if 240 schedules exist. The seed script creates 240 schedules (30 days × 8), so ScheduleId should go up to 240. Seeding only 1-60 leaves the remaining 180 schedules with no registrations. Change the loop to cover all 240 or document why only the first 60 are seeded.

</details>

<details>
<summary>Details</summary>

## Schema migration idempotency gap

COMPLETE_SCHEMA_FIX.sql uses IF NOT EXISTS checks for adding columns (good), but sp_rename and ALTER COLUMN statements run unconditionally. Example from Invoices:

```sql
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'Amount')
AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'TotalAmount')
BEGIN
    EXEC sp_rename 'Invoices.Amount', 'TotalAmount', 'COLUMN';
    PRINT '✓ Renamed Amount to TotalAmount';
END
```

This rename works once. On the second run, both checks pass (Amount doesn't exist, TotalAmount does), so the block is skipped. But if the migration is run partially (sp_rename succeeds but a later statement fails), re-running will fail because the column is already renamed. The same issue affects IssueDate → InvoiceDate and QRCodeValue → QRCode renames.

ALTER COLUMN statements have a similar issue. For example, making MembershipId nullable:

```sql
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'MembershipId' AND is_nullable = 0)
BEGIN
    -- Drop FK constraint first
    ...
    ALTER TABLE Invoices ALTER COLUMN MembershipId INT NULL;
    -- Re-add FK constraint
    ...
END
```

If the FK drop succeeds but ALTER COLUMN fails, re-running will skip the block (is_nullable = 0 check fails because the column is now nullable), leaving the FK constraint missing.

Recommendation: wrap each ALTER COLUMN in a transaction or add existence checks for FK constraints before attempting to drop them.

## Schedules table destructive transformation

The Schedules fix combines ScheduledDate (DATE) + StartTime (TIME) + EndTime (TIME) into StartTime (DATETIME2) + EndTime (DATETIME2). The migration checks if StartTime is of type 'time', and if so:

1. Creates StartDateTime and EndDateTime columns (DATETIME2)
2. Combines ScheduledDate + StartTime/EndTime into the new columns
3. Drops ScheduledDate, StartTime (TIME), EndTime (TIME)
4. Renames StartDateTime → StartTime, EndDateTime → EndTime
5. Makes the new columns NOT NULL

This transformation is irreversible without a backup. If the original schema had TIME columns, they're permanently removed. The migration doesn't create a backup table or log the original values.

The seed script (COMPLETE_SEED_DATA.sql) assumes the new schema and inserts DATETIME2 values directly:

```sql
INSERT INTO Schedules (TrainerId, FacilityId, ClassName, StartTime, EndTime, MaxCapacity, ...)
VALUES 
(1, 1, N'Thể Hình Sáng', DATEADD(HOUR, 6, @ScheduleDate), DATEADD(HOUR, 8, @ScheduleDate), 20, ...)
```

So the seed script will only work after the schema fix. Running it before the fix will fail (wrong column names).

Recommendation: document the Schedules transformation as a breaking change and require a full backup before running. Or, keep the old columns and add new computed columns instead of replacing.

## Invoice MemberId handling

The InvoiceRepository.CreateAsync method now includes MemberId in the INSERT:

```sql
INSERT INTO Invoices (MemberId, MembershipId, TotalAmount, InvoiceDate, DueDate, Status, Description, ...)
VALUES (@MemberId, @MembershipId, @TotalAmount, ...)
```

MembershipService.CreateAsync sets invoice.MemberId before calling the repository:

```csharp
var invoice = new Invoice
{
    MemberId = membership.MemberId,  // FIX: Add MemberId
    MembershipId = membership.MembershipId,
    ...
};
await _invoiceRepo.CreateAsync(invoice);
```

This closes the gap identified in the review criteria. However, the fix assumes membership.MemberId is always set. If CreateAsync is ever called with a null or 0 MemberId in the request, the invoice will have MemberId=0, violating the FK constraint (or creating an orphaned invoice if MemberId=0 is allowed).

The controller's Purchase endpoint includes a role check to prevent members from buying for other members, which mitigates the risk of malicious MemberId injection. But there's no validation in the service layer to ensure MemberId is valid (exists in Members table) before creating the invoice.

## Membership cancellation ownership check

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

The controller calls this method differently for Member vs Admin:

- **Member**: passes userMemberId (from JWT claim) as requestingMemberId → service checks entity.MemberId == userMemberId → member can only cancel own
- **Admin**: fetches membership, then passes membership.MemberId as requestingMemberId → service checks entity.MemberId == membership.MemberId → always passes (same ID)

So the admin path bypasses the ownership check by design. The service method's parameter name "requestingMemberId" is misleading in the admin case — it's actually the owner's ID, not the requester's ID.

This isn't a security bug (the controller enforces role checks), but the API design is confusing. A clearer approach: remove the ownership check from the service layer entirely, and enforce it only in the controller. Or, add a separate CancelAsync overload for admin use that doesn't take requestingMemberId.

## Payments.MemberId default value risk

COMPLETE_SCHEMA_FIX.sql adds Payments.MemberId with DEFAULT 0:

```sql
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Payments') AND name = 'MemberId')
BEGIN
    ALTER TABLE Payments ADD MemberId INT NOT NULL DEFAULT 0;
    ...
    ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId);
END
```

If the Payments table already has rows when this migration runs, all existing rows will get MemberId=0. If no Member with MemberId=0 exists, the FK constraint will fail. If MemberId=0 is allowed (e.g., a placeholder member), existing payments will incorrectly link to that placeholder.

The seed script (COMPLETE_SEED_DATA.sql) avoids this by clearing all data before seeding:

```sql
DELETE FROM Payments;
DELETE FROM Invoices;
...
```

So the DEFAULT 0 is only used during the migration, not during normal operation. But if the schema fix is run against a database with existing data, it will fail.

Recommendation: either make Payments.MemberId nullable (DEFAULT NULL), or add a migration step to backfill MemberId from Invoices before adding the FK constraint:

```sql
ALTER TABLE Payments ADD MemberId INT NULL;
UPDATE Payments SET MemberId = (SELECT TOP 1 MemberId FROM Invoices WHERE Invoices.InvoiceId = Payments.InvoiceId);
ALTER TABLE Payments ALTER COLUMN MemberId INT NOT NULL;
ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Members FOREIGN KEY (MemberId) REFERENCES Members(MemberId);
```

## Seed data Users.MemberId consistency

COMPLETE_SEED_DATA.sql creates Users for SuperAdmin, Trainers, and Members. Only Member users set the MemberId column:

```sql
-- SuperAdmin (no MemberId)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, ...)
VALUES ('gymadmin', '$2a$10$...', N'System Administrator', 'admin@gym.com', 'SuperAdmin', 1, ...);

-- Trainers (no MemberId)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, ...)
VALUES ('trainer1', '$2a$10$...', N'Nguyễn Văn Hùng', 'hung.trainer@gym.com', 'Trainer', 1, ...);

-- Members (with MemberId)
INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, MemberId, ...)
VALUES ('member1', '$2a$10$...', N'Nguyễn Thị Hoa', 'hoa.nguyen@gmail.com', 'Member', 1, 1, ...);
```

The schema fix (COMPLETE_SCHEMA_FIX.sql) adds Users.MemberId as nullable:

```sql
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'MemberId')
BEGIN
    ALTER TABLE Users ADD MemberId INT NULL;
END
```

No FK constraint is added between Users.MemberId and Members.MemberId (intentional — not all users are members). If code elsewhere assumes Users.MemberId is always set (e.g., reading it from JWT claims without null checks), it will break for non-member users.

## Frontend cancel button integration

The cancel button only appears for active memberships (EndDate >= today), matching the backend's cancellation logic (UPDATE ... WHERE EndDate > today). If a membership expires between page load and button click, the backend returns false (no rows updated), and the frontend shows a generic "Lỗi hủy gói: ..." message with no indication the membership was already expired. The controller could return a more specific error for this case.

</details>

## File map

<details>
<summary>Changed files</summary>

**SQL2/COMPLETE_SCHEMA_FIX.sql** — Schema migration script: adds/removes/renames columns in Memberships, Invoices, Payments, Schedules, Sessions, Checkins, Members, Users to match C# entities. Includes destructive Schedules transformation (DATE+TIME → DATETIME2).

**SQL2/COMPLETE_SEED_DATA.sql** — Development seed data: clears tables and inserts 1 SuperAdmin, 5 trainers, 30 members, 50 memberships, 240 schedules, 600 sessions, 100 checkins, matching invoices/payments.

**SQL2/RUN_COMPLETE_FIX.sql** — Master script: runs COMPLETE_SCHEMA_FIX.sql then COMPLETE_SEED_DATA.sql using :r directives.

**DAL/Repositories/Implementations/InvoiceRepository.cs** — Added MemberId to INSERT statement in CreateAsync method.

**Service/BUS/Implementations/MembershipService.cs** — Set invoice.MemberId = membership.MemberId in CreateAsync before calling repository. Added CancelAsync method with ownership check.

**DAL/Repositories/Implementations/MembershipRepository.cs** — Added CancelAsync method: UPDATE Memberships SET EndDate = today WHERE MembershipId = @id AND EndDate > today.

**DAL/Repositories/Interfaces/IMembershipRepository.cs** — Added CancelAsync method signature.

**Service/BUS/Interfaces/IMembershipService.cs** — Added CancelAsync method signature.

**Controllers/MembershipController.cs** — Added POST {id}/cancel endpoint: Admin can cancel any membership, Member can only cancel own (verified by ownership check in service).

**wwwroot/js/memberships.js** — Added cancelMembership function: confirms with user, calls POST /api/Membership/{id}/cancel, reloads membership list on success.

[Full diff: `git diff main` in project root]

</details>
