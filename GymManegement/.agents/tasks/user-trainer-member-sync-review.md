# Auto-create Trainer/Member records on user role assignment (v2)

This revision addresses all blocking concerns from the prior review. The QRCode race condition is eliminated by switching to an insert-then-update pattern: Member records are created with a temporary QRCode, then immediately updated with the actual MemberId-based QRCode. Console.WriteLine logging is replaced with ILogger for structured logging that persists in production. The SQL migration follows the same two-phase pattern, inserting Members with TEMP_ prefixed QRCodes and updating them in a separate step.

**Watch for:** Nothing blocking. The insert-then-update pattern trades one UPDATE query per Member creation for guaranteed correctness. Email uniqueness enforcement is still assumed but not verified in this change.

**Verdict**: APPROVED

## High-level view

The QRCode generation now happens after the Member record is inserted, using the database-assigned MemberId. `RegisterAsync`, `UpdateUserRoleAsync`, and the SQL migration all follow the same pattern: insert with `QRCode = "TEMP"` (or `TEMP_{UserId}` in the migration), then immediately update `SET QRCode = 'M' + RIGHT('000000' + CAST(MemberId AS VARCHAR), 6)`. This is transactionally safe against concurrent inserts—each thread sees its own assigned MemberId.

Logging is now injected via ILogger<AuthService> and uses structured logging methods (LogInformation, LogWarning) with message templates. Logs include contextual parameters (Email, UserId, Role, QRCode) that will be captured by logging infrastructure.

The SQL migration's verification query now includes `m.QRCode` in the SELECT and checks for `QRCODE NOT UPDATED` status when `QRCode LIKE 'TEMP_%'`, making it easier to diagnose incomplete migrations.

<details>
<summary>Issues (0)</summary>

No blocking issues. All concerns from the prior review are resolved.

</details>

<details>
<summary>Details</summary>

## QRCode generation fixed in RegisterAsync and UpdateUserRoleAsync

The previous implementation queried `IDENT_CURRENT('Members') + 1` to predict the next MemberId before insert, creating a race condition where concurrent registrations could generate duplicate QRCodes. The new implementation inserts the Member with `QRCode = "TEMP"`, then immediately updates it using the database-assigned `member.MemberId`:

```csharp
var member = new Member { /* ... */, QRCode = "TEMP" };
await _memberRepo.CreateAsync(member);

using var conn = _db.CreateConnection();
var qrCode = $"M{member.MemberId:D6}";
await conn.ExecuteAsync(
    "UPDATE Members SET QRCode = @QRCode, UpdatedAt = GETDATE() WHERE MemberId = @MemberId",
    new { QRCode = qrCode, member.MemberId });
```

The MemberId is populated by the CreateAsync method (likely via OUTPUT INSERTED.MemberId or SCOPE_IDENTITY). If the repository doesn't populate it, the UPDATE will fail silently (WHERE MemberId = 0 matches nothing), leaving QRCode as "TEMP". The calling code doesn't check whether the UPDATE succeeded.

## SQL migration updated

Step 2 now inserts Members with `QRCode = 'TEMP_' + CAST(u.UserId AS VARCHAR)` instead of calculating ROW_NUMBER + MAX(MemberId). Step 3 (new) updates all TEMP_ QRCodes to the MemberId-based format:

```sql
UPDATE Members
SET QRCode = 'M' + RIGHT('000000' + CAST(MemberId AS VARCHAR), 6),
    UpdatedAt = GETDATE()
WHERE QRCode LIKE 'TEMP_%';
```

The WHERE clause ensures idempotency—running the migration twice won't re-update already-corrected QRCodes. The verification query (Step 4) now checks for `QRCODE NOT UPDATED` status, catching cases where the UPDATE step failed or was skipped.

## Email uniqueness assumption unchanged

The code still assumes that Trainers and Members tables enforce unique email constraints (via database index or application logic in the repositories). If they don't, `GetByEmailAsync` could return null but `CreateAsync` could fail on a duplicate email insert. The try-catch swallows the error, leaving the User without a Trainer/Member record. This assumption was present in the prior version and is unchanged in this revision. Verifying the constraint is out of scope for this change but should be confirmed before production deployment.

</details>

<details>
<summary>File map</summary>

**Modified:**
- `Service/BUS/Implementations/AuthService.cs` — Replaced QRCode pre-calculation with insert-then-update pattern in RegisterAsync and UpdateUserRoleAsync; replaced Console.WriteLine with ILogger; added ILogger constructor parameter
- `.agents/tasks/fix-missing-trainer-member-records.sql` — Changed Member insert to use TEMP_ QRCodes; added Step 3 to update QRCodes post-insert; added QRCode column and TEMP_ check to verification query

[Full diff](git diff HEAD~1 HEAD -- Service/BUS/Implementations/AuthService.cs .agents/tasks/fix-missing-trainer-member-records.sql)

</details>
