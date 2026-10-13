# Trainer role-based frontend filtering and Member feature inheritance

This change extends the Trainer role to inherit all Member features (memberships, personal schedule, check-ins, profile) and adds session management capabilities. Trainers now see only their own schedules and sessions, with auto-filled trainer selection in creation modals. The dashboard gains two new statistics: pending session approvals and weekly session count.

**Watch for:** Trainers can edit or approve sessions for schedules they don't own (likely); no backend ownership validation enforces that a trainer can only modify their own resources (confirmed); performance degradation when a trainer has many schedules due to N+1 API calls in dashboard stats (confirmed); email-based trainerId lookup fails silently if JWT email doesn't match database exactly (confirmed); disabled trainer dropdown in schedule creation may not submit trainerId (possible).

**Verdict**: NEEDS_CHANGES

## High-level view

The change adds role-based filtering to schedules and sessions by fetching all records then filtering client-side by trainerId. Trainers get access to Member-only pages by adding them to the `allowedPagesByRole` map. The schedule creation modal pre-fills and disables the trainer dropdown for Trainer role. The session creation modal filters available schedules to only those owned by the logged-in trainer. Dashboard statistics for trainers now include counts of pending registrations and weekly sessions, both calculated by iterating through schedules and fetching sessions for each in serial. The trainerId is resolved by fetching all trainers and matching by email from the JWT token.

Authorization remains at the controller level with `[Authorize(Roles = "...")]` attributes. Trainers share POST and PUT permissions with Admin but are blocked from DELETE. No backend service-layer check prevents a trainer from updating or approving sessions for schedules owned by another trainer—the frontend filtering is the sole enforcement mechanism.

<details>
<summary>Issues (9)</summary>

1. **No backend ownership validation** — A trainer can call `PUT /api/Schedule/{id}` or `PUT /api/Session/{id}/status` for any schedule/session, not just their own. Add ownership checks in ScheduleService.UpdateAsync and SessionService.UpdateAsync that verify the authenticated user's trainerId matches the resource's trainerId before allowing the update.

2. **Dashboard N+1 queries** — `loadTrainerPendingSessions` and `loadTrainerWeeklySessions` loop through up to 50 schedules and call `/api/Session/schedule/{scheduleId}` for each, causing 50+ sequential API requests. Introduce a backend endpoint `/api/Session/trainer/{trainerId}` that returns all sessions for a trainer's schedules in one query, then filter client-side.

3. **Silent trainerId lookup failure** — If JWT email doesn't match trainer database email (case mismatch, typo, missing), `getTrainerId()` returns null and the UI shows "Không tìm thấy thông tin trainer" with no actionable guidance. Log the failure reason (email not found, API error) and display it to the user so they can report the issue or fix their profile.

4. **Session filtering fetches all sessions** — `filterSessionsByTrainer` calls `/api/Session?pageNumber=1&pageSize=10000` to get all sessions then filters client-side. For gyms with >10k sessions this silently truncates results; for smaller gyms it's unnecessary data transfer. Add `/api/Session/trainer/{trainerId}` backend endpoint to filter server-side.

5. **Trainer can approve any session via API** — Frontend hides buttons for sessions outside the trainer's schedules, but the API endpoint `PUT /api/Session/{id}/status` accepts any sessionId. A trainer could approve/reject sessions for another trainer's class by calling the API directly. Add a check in SessionService.UpdateAsync that the session's schedule belongs to the authenticated trainer (or is Admin).

6. **No capacity enforcement** — Session creation doesn't check if the schedule's maxCapacity has been reached. A trainer could approve 100 registrations for a class with maxCapacity=10. Add a validation step in session approval that counts existing 'Approved' sessions for the schedule and rejects if at capacity.

7. **Cached trainerId persists across logins** — `_cachedTrainerId` is a module-level variable that never clears. If a user logs out and a different user logs in (same browser session without page reload), the old trainerId is reused. Clear `_cachedTrainerId` in the `logout()` function in auth.js.

8. **Disabled trainer dropdown doesn't submit** — The schedule creation modal disables the trainer dropdown for Trainer role, but disabled form fields don't submit their values. The form handler must explicitly read the disabled field or use a hidden input. Verify schedule creation works for Trainer role; if trainerId is missing from POST, change the field to readonly or add a hidden input.

9. **Email lookup normalizes case but not whitespace** — `getTrainerId()` compares emails with `.toLowerCase()` on both sides, but doesn't trim whitespace. If the database has trailing spaces or the JWT has a display name, the lookup fails. Trim both sides and consider returning trainerId in the JWT claims instead of relying on email lookup.

</details>

<details>
<summary>Details</summary>

## Client-side schedule filtering with no backend ownership guard

Trainers see only their own schedules by calling `/api/Schedule/trainer/{trainerId}` in `loadSchedules()`. This endpoint exists and correctly filters schedules by trainerId. The issue is that the UPDATE and DELETE operations have no corresponding ownership check. The controller has `[Authorize(Roles = "SuperAdmin,Admin,Trainer")]` on `PUT /api/Schedule/{id}`, which means any authenticated trainer can update any schedule by sending a PUT request with someone else's scheduleId.

The `ScheduleService.UpdateAsync` method accepts the scheduleId and request body but does not verify that `entity.TrainerId` matches the authenticated user's trainerId. A malicious or confused trainer could edit another trainer's class by calling the API directly (bypassing the UI's disabled dropdown).

The same gap exists for sessions: `SessionService.UpdateAsync` and the `/api/Session/{id}/status` endpoint allow any trainer to approve or reject any session. Frontend filtering hides the buttons, but the backend doesn't enforce ownership.

For Trainer role to be truly scoped, the service layer must check that the authenticated user owns the resource. Retrieve the trainerId from the JWT claims (or via the user email → trainer lookup), fetch the existing schedule/session, compare TrainerId, and return 403 Forbidden if they don't match.

## Dashboard statistics with sequential API fanout

The new dashboard cards "Yêu Cầu Chờ Duyệt" and "Buổi Tập Tuần Này" are calculated in `loadTrainerPendingSessions` and `loadTrainerWeeklySessions`. Both functions fetch the trainer's schedules, extract scheduleIds, then loop through up to 50 schedules calling `/api/Session/schedule/{scheduleId}` for each.

```javascript
for (const scheduleId of limitedScheduleIds) {
    const sessions = await apiFetch(`/api/Session/schedule/${scheduleId}`);
    // count and accumulate
}
```

This is a classic N+1 problem. If a trainer has 50 schedules, the dashboard makes 51 API calls (1 for schedules, 50 for sessions). Each call has network overhead and backend query latency. The calls are sequential (await in a for loop), so total load time is 50 × average-response-time.

A backend endpoint `/api/Session/trainer/{trainerId}` that joins Session → Schedule → Trainer and filters by trainerId would return all sessions in one query. The frontend could then filter by status and date range locally. This would drop the dashboard load from 51 calls to 2 calls.

## Email-based trainerId resolution with silent failure

`getTrainerId()` fetches all trainers and finds the one whose email matches the JWT user email. If no match is found, it returns null. The calling code checks `if (!trainerId)` and displays "Không tìm thấy thông tin trainer" but doesn't explain why.

Possible failure modes:
- JWT email is missing (shouldn't happen if auth is working, but defensive code should handle it)
- Trainer email in database doesn't match JWT email (typo, email changed, case mismatch despite .toLowerCase())
- API call to `/api/Trainer` fails (network error, backend down, authorization issue)

The current code logs to console but the user sees a generic error. A better UX would show "Không tìm thấy trainer với email: trainer@gym.com" or "Lỗi tải danh sách HLV" depending on the failure reason.

Longer term, the JWT token should include a `trainerId` claim so this lookup is unnecessary. The login endpoint already returns `memberId` for Member role; it should return `trainerId` for Trainer role.

## Session list filtering by fetching all sessions

When a trainer views the sessions page, `loadSessions()` calls `/api/Session?pageNumber=1&pageSize=10000` to get all sessions, then `filterSessionsByTrainer` fetches the trainer's schedules and filters sessions by scheduleId.

The pageSize=10000 is a workaround for pagination breaking client-side filtering, but it introduces a silent data loss bug: if there are more than 10,000 sessions, the API only returns the first 10,000, and the trainer never sees sessions beyond that. The trainer might think they have no pending registrations when in fact they're on page 2.

The correct fix is a backend endpoint that filters sessions by trainerId before pagination: `/api/Session/trainer/{trainerId}?pageNumber=1&pageSize=50`. This also eliminates the need for `filterSessionsByTrainer` client-side logic and reduces the payload size (no need to transfer sessions for other trainers).

## Schedule creation modal auto-fills trainerId but disabled fields don't submit

The modal disables the trainer dropdown and pre-selects the logged-in trainer's ID for Trainer role. A disabled `<select>` doesn't send its value in the form submission—the browser skips disabled fields. The form submit handler must explicitly read the disabled field's value or set a hidden input with the trainerId. If the form uses `new FormData(form)`, the trainerId won't be included.

## No pagination for Trainer views

When Trainer role views schedules or sessions, the code bypasses pagination and shows all results in one page. For small gyms where a trainer has <100 schedules and <1000 sessions, this works. For large gyms, a trainer with 500 schedules would see a very long table with no way to page through it. The UI doesn't show pagination controls when totalPages=1, so the user doesn't see broken prev/next buttons, but the table could still be unwieldy.

## File map

</details>

<details>
<summary>File map</summary>

- **wwwroot/js/app.js**: Added 'memberships' and 'member-schedule' to Trainer's allowedPagesByRole list
- **wwwroot/js/dashboard.js**: Added two stat cards to Trainer dashboard (pending sessions, weekly sessions) with functions to calculate them by looping through schedules and fetching sessions
- **wwwroot/js/schedules.js**: Added role check in loadSchedules() to call /api/Schedule/trainer/{trainerId} for Trainer role; added auto-fill and disable logic in schedule creation modal to pre-select logged-in trainer
- **wwwroot/js/sessions.js**: Added role check in loadSessions() to fetch all sessions then filter by trainer's schedules; added filterSessionsByTrainer() function; added role check in session creation modal to filter schedules dropdown to trainer's own schedules

[Full diff](git diff 8658b46..HEAD)

</details>
