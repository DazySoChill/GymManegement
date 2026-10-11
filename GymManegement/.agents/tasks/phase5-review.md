# Member Schedule Preferences implementation

Phase 5 adds a member-facing weekly schedule preference system. Members select training days and time slots through a simple checkbox interface. The feature uses a new table (MemberSchedulePreferences) with a dedicated repository, service, and controller stack. The existing Schedules and Sessions subsystems are untouched.

**Watch for:** getMemberId() not imported or defined in member-schedule.js **(likely)**; TimeSpan string format from `<input type="time">` may not parse correctly without test **(possible)**; no member ownership validation in Create/Update/Delete allows cross-member manipulation **(confirmed)**.

**Verdict**: NEEDS_CHANGES

## High-level view

The backend follows the standard layered pattern: Entity → Repository (Dapper) → Service (validation + business logic) → Controller. MemberSchedulePreference entity tracks PreferenceId, MemberId, DayOfWeek (0-6), StartTime/EndTime (TimeSpan), IsActive flag, and audit timestamps. The repository implements soft-delete via IsActive=0. Service layer validates day range (0-6), member existence, and time ordering (EndTime > StartTime). Controller exposes GET by member, GET by day (Admin/Trainer only), POST/PUT/DELETE.

Frontend member-schedule.js renders a checkbox grid for days of the week, two time inputs, and a submit handler that creates one preference per selected day. The schedule list groups preferences by day and displays them with delete buttons. All API calls use the global apiFetch helper with Bearer token injection.

Database migration SQL (03_ADD_MEMBER_SCHEDULE_PREFERENCES.sql) creates the table with foreign key to Members, check constraints on DayOfWeek and time ordering, and indexes on MemberId and DayOfWeek.

Navigation was added to app.js (member-schedule route, renderMemberSchedule function call), pageMap defines the menu item (📅 Lịch Tập Của Tôi), and roleAccess grants Member role access. Script tag was added to index.html. DI registrations for both repository and service are present in Program.cs.

<details>
<summary>Issues (3)</summary>

1. **getMemberId() undefined** — member-schedule.js calls getMemberId() but the function is not defined in that file or imported from another module. Likely defined in api.js or auth.js, but without explicit import or global declaration, this will throw ReferenceError at runtime.

2. **TimeSpan string format mismatch** — frontend sends time as "HH:MM" string from `<input type="time">`, but backend expects TimeSpan. ASP.NET Core model binding likely handles this, but without explicit test, there's risk of TimeSpan.Zero if parsing fails. Verify with integration test or add explicit logging.

3. **No member ownership validation** — MemberSchedulePreferenceController endpoints (Create, Update, Delete, GetByMember) don't verify that the requesting member's JWT claim matches the target MemberId. A member could create, update, delete, or view another member's preferences by manipulating request parameters. Extract memberId from User.FindFirst("memberId") and validate against request/entity.

</details>

<details>
<summary>Details</summary>

## Entity and database schema alignment

SQL TIME maps to C# TimeSpan. Indexes on MemberId and DayOfWeek support the repository queries. Foreign key to Members ensures referential integrity. Check constraints enforce DayOfWeek range (0-6) and time ordering (EndTime > StartTime) at database level.

Timestamps use DateTime.UtcNow in repository but SQL DEFAULT GETDATE() (local server time). Repository always supplies values explicitly, so SQL default never runs, but mixing UTC and local semantics is a code smell. Consider GETUTCDATE() in SQL or document the choice.

## Repository implementation

MemberSchedulePreferenceRepository uses Dapper with raw SQL. All GET methods filter by IsActive = 1 (soft-delete). CreateAsync uses OUTPUT INSERTED.PreferenceId to return new ID. DeleteAsync sets IsActive = 0 and updates UpdatedAt.

## Service validation and business logic

MemberSchedulePreferenceService.CreateAsync validates member existence, DayOfWeek range (0-6), and EndTime > StartTime. UpdateAsync validates day and time but assumes MemberId is already valid. DeleteAsync soft-deletes via repository.

GetByMemberIdAsync fetches member once outside loop. GetByDayOfWeekAsync fetches member for each preference in a loop. For N preferences across M members on the same day, this makes M member API calls. If 50 members have 3 preferences each for Monday, GetByDayOfWeekAsync makes 50 lookups. Consider batch fetch or cache.

## Controller authorization and routing

MemberSchedulePreferenceController is [Authorize] at class level. GetByDayOfWeek is further restricted to Admin/Trainer roles.

GetByMember, Create, Update, and Delete do not validate that the requesting member's JWT claim matches the target MemberId. A member can query, create, update, or delete another member's preferences by manipulating parameters. Extract memberId from User.FindFirst("memberId") and compare against request/entity MemberId.

## Frontend rendering and form handling

member-schedule.js calls getMemberId() which is not defined in that file. If getMemberId() is missing at runtime, the code throws ReferenceError and the page doesn't render.

Day checkboxes use values 0-6 (Sunday=0, Monday=1, ..., Saturday=6), matching backend DayOfWeek int.

Form submit handler validates at least one day selected, times non-empty, endTime > startTime. For each selected day, posts to /api/MemberSchedulePreference with memberId, dayOfWeek, startTime, endTime. `<input type="time">` produces "HH:MM" strings. Backend expects TimeSpan. ASP.NET Core model binding may parse this, but without test, there's risk StartTime and EndTime become TimeSpan.Zero if parsing fails.

## Schedule list rendering and deletion

loadSchedules groups preferences by dayOfWeek and displays each day group sorted Monday-first. formatTimeSpan strips seconds from backend's "HH:MM:SS" TimeSpan JSON serialization, returning "HH:MM". Delete button calls deleteSchedule which sends DELETE then refreshes the list.

## Navigation and DI

app.js adds member-schedule to Member roleAccess, defines pageMap entry, and calls renderMemberSchedule in loadPage switch. index.html includes member-schedule.js script tag. Program.cs registers IMemberSchedulePreferenceRepository and IMemberSchedulePreferenceService once each (lines 26 and 41).

## No changes to Schedules/Sessions

No references to MemberSchedulePreference in schedules.js, sessions.js, ScheduleController.cs, or SessionController.cs. Constraint respected.

</details>

## File map

<details>
<summary>Changed files</summary>

- **DAL/Entities/MemberSchedulePreference.cs** — Entity for weekly schedule preferences (day, time range, member FK)
- **DAL/Repositories/Interfaces/IMemberSchedulePreferenceRepository.cs** — Repository interface with GetByMemberId and GetByDayOfWeek
- **DAL/Repositories/Implementations/MemberSchedulePreferenceRepository.cs** — Dapper repository with soft-delete pattern
- **Service/BUS/Interfaces/IMemberSchedulePreferenceService.cs** — Service interface for CRUD operations
- **Service/BUS/Implementations/MemberSchedulePreferenceService.cs** — Business logic, validation (day range, member exists, time ordering), member name resolution
- **API/DTOs/MemberSchedule/CreateMemberScheduleRequest.cs** — DTO for creating preference (MemberId, DayOfWeek, StartTime, EndTime)
- **API/DTOs/MemberSchedule/UpdateMemberScheduleRequest.cs** — DTO for updating preference (DayOfWeek, StartTime, EndTime, IsActive)
- **API/DTOs/MemberSchedule/MemberScheduleResponse.cs** — DTO for response (includes MemberName, DayOfWeekName, all entity fields)
- **Controllers/MemberSchedulePreferenceController.cs** — REST API (GET by member/day, POST, PUT, DELETE)
- **wwwroot/js/member-schedule.js** — Frontend UI (day checkboxes, time inputs, schedule list, delete)
- **wwwroot/js/app.js** — Added member-schedule route to roleAccess and pageMap, case handler in loadPage
- **wwwroot/index.html** — Added script tag for member-schedule.js
- **Program.cs** — DI registrations for repository and service
- **SQL2/03_ADD_MEMBER_SCHEDULE_PREFERENCES.sql** — Database migration (table, constraints, indexes)

</details>
