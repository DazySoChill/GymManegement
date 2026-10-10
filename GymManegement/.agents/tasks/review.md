# SQL injection fix, DTO alignment, and datetime guard

TrainerRepository pagination now validates sortBy and sortDir parameters before SQL interpolation. Schedule DTO matches test format (DateTime fields with ISO 8601 strings). Session service guards against DateTime.MinValue to prevent SQL datetime out-of-range errors. All three issues from the prior review were addressed.

**Watch for:** Nothing blocking. All stored procedures removed, DTOs match database schema, datetime handling is safe.

**Verdict**: APPROVED

## High-level view

TrainerRepository's paginated GetAllAsync added a whitelist check for sortBy (validates against seven allowed column names) and restricts sortDir to "ASC" or "DESC" before string interpolation. This closes the SQL injection vector from the prior review.

Schedule DTO uses DateTime for StartTime and EndTime, matching the database DATETIME columns. The test documentation now uses ISO 8601 format ("2025-01-20T06:00:00"), so model binding will work correctly. ClassName and MaxCapacity fields are present.

Session service CreateAsync checks if RegistrationDate is default(DateTime) or DateTime.MinValue and replaces it with DateTime.UtcNow before creating the entity. This prevents SQL Server "datetime out-of-range" errors when the client omits the field or sends null.

All stored procedure calls in TrainerRepository were removed and replaced with direct parameterized SQL. Soft delete (IsDeleted=1) is used throughout. INSERT returns the identity via OUTPUT INSERTED.TrainerId. Build succeeds.

<details>
<summary>Details</summary>

## TrainerRepository SQL injection fix

GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir) now validates sortBy against a whitelist before interpolation:

```csharp
var allowedSortColumns = new[] { "TrainerId", "FullName", "Email", "Phone", "Specialization", "CreatedAt", "UpdatedAt" };
sortBy = !string.IsNullOrEmpty(sortBy) && allowedSortColumns.Contains(sortBy) ? sortBy : "TrainerId";
sortDir = sortDir?.ToUpperInvariant() == "DESC" ? "DESC" : "ASC";
```

If sortBy is not in the whitelist, it defaults to "TrainerId". sortDir is normalized to uppercase and forced to "ASC" or "DESC". The prior review flagged direct interpolation as a SQL injection vector; this change fixes it.

## Schedule DTO and test format alignment

The prior review flagged a mismatch where test documentation showed dayOfWeek + time strings. Test documentation was updated to use ISO 8601 DateTime format ("2025-01-20T06:00:00"). CreateScheduleRequest.cs uses DateTime for StartTime and EndTime, matching the database DATETIME columns and the test format.

## Session RegistrationDate datetime guard

CreateSessionRequest field initializer provides DateTime.UtcNow as default. If the client explicitly sends `"registrationDate": null` or JSON deserialization bypasses the initializer, the field could be DateTime.MinValue (0001-01-01). SQL Server DATETIME minimum is 1753-01-01, causing an out-of-range error.

SessionService.CreateAsync guards against this:
```csharp
var registrationDate = request.RegistrationDate == default || request.RegistrationDate == DateTime.MinValue
    ? DateTime.UtcNow
    : request.RegistrationDate;
```

The service replaces default(DateTime) or DateTime.MinValue with DateTime.UtcNow before creating the entity. This prevents the out-of-range error regardless of how the client sends the request.

## Stored procedure removal in TrainerRepository

All methods use direct parameterized SQL. No `sp_Trainer_*` calls remain. INSERT uses OUTPUT INSERTED.TrainerId to return the identity. UPDATE sets UpdatedAt to DateTime.UtcNow. DELETE is soft delete (IsDeleted = 1).

</details>

<details>
<summary>File map</summary>

- **DAL/Repositories/Implementations/TrainerRepository.cs** — Added whitelist validation for sortBy parameter (allowedSortColumns array) and normalized sortDir to prevent SQL injection in paginated GetAllAsync. All stored procedures removed, replaced with direct parameterized SQL. Soft delete implemented.

- **API/DTOs/Schedule/CreateScheduleRequest.cs** — Fields match database schema (TrainerId, FacilityId, ClassName, StartTime as DateTime, EndTime as DateTime, MaxCapacity). Test documentation uses ISO 8601 format. No issues.

- **API/DTOs/Session/CreateSessionRequest.cs** — RegistrationDate defaults to DateTime.UtcNow via field initializer. Service layer checks for DateTime.MinValue and replaces with DateTime.UtcNow before repository call to prevent SQL datetime out-of-range errors.

- **Service/BUS/Implementations/SessionService.cs** — CreateAsync method added guard to check `request.RegistrationDate == default || request.RegistrationDate == DateTime.MinValue` and replace with DateTime.UtcNow before creating entity.

- **COMPREHENSIVE_API_TEST.md** — Schedule test examples updated to use ISO 8601 DateTime format ("2025-01-20T06:00:00") instead of dayOfWeek + time strings. Matches DTO expectations.

Full diff: Addresses issues 1, 2, and 3 from review 2026-10-10-091348.

</details>
