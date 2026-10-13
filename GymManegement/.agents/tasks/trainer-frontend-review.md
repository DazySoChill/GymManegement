# Trainer frontend: sessions and check-in management

Adds two new trainer-specific views: session approval (renderTrainerSessions) and manual check-in (renderTrainerCheckins). Trainers see only their own schedules fetched via email-based trainerId lookup. Session approval and check-in submission call backend endpoints that enforce ownership validation. The routing layer dispatches Trainer role to these functions. Empty states handle zero schedules. Error messages surface email when trainer lookup fails.

**Watch for:** Nothing blocking — backend ownership guards are confirmed, cache clearing is implemented, error messages show user email, empty states handle zero schedules, and API calls are correct.

**Verdict**: APPROVED

## High-level view

Session management fetches all schedules, filters client-side by trainerId, then fetches sessions per schedule. Trainers approve or reject registrations with status='Registered' via PUT /api/Session/{id}. Backend validates that the session's schedule belongs to the authenticated trainer before allowing the update.

Check-in management populates a schedule dropdown filtered by trainerId, then populates a member dropdown with approved sessions for the selected schedule. Submission calls POST /api/Checkin/manual with the memberId. Backend validates that the member is enrolled in at least one of the trainer's schedules before allowing check-in.

Routing in app.js correctly dispatches renderSessions() and renderCheckins() to trainer-specific functions when role==='Trainer'. TrainerId lookup calls GET /api/Trainer, matches by email (case-insensitive, whitespace-trimmed), caches the result, and clears cache on logout. Error messages include the user email when lookup fails. Empty state displays when a trainer has zero schedules.

<details>
<summary>Issues (0)</summary>

No blocking issues found. All critical concerns from prior reviews have been addressed:
- Backend ownership validation confirmed in SessionService.UpdateAsync and CheckinService.CreateManualAsync
- Cache clearing implemented in logout() function in auth.js
- Error messages improved to show user email when trainer lookup fails
- Empty state handling added for trainers with zero schedules
- API endpoint correctness verified

</details>

<details>
<summary>Details</summary>

## Session approval flow

renderTrainerSessions (lines 495-543 in sessions.js) calls getTrainerId(), fetches all schedules, filters by trainerId matching s.trainerId or s.TrainerId, then loops through trainerSchedules calling `/api/Session/schedule/{scheduleId}` for each. Sessions are merged into allSessions with className and trainerName from the schedule. Filter buttons ('all' vs 'pending') apply status='Registered' filter client-side.

Approve and reject buttons call approveTrainerSession/rejectTrainerSession (lines 709-773), which PUT to `/api/Session/{sessionId}` with status='Approved' or 'Cancelled'. Backend SessionService.UpdateAsync (SessionService.cs lines 192-219) validates that if userRole==='Trainer', the session's schedule.TrainerId must match the trainer found by email lookup. If not, throws UnauthorizedAccessException with message "Bạn chỉ có thể duyệt đăng ký cho lớp học của mình."

The table correctly shows sessionId, memberName (with fallback to `Member ${memberId}`), className, registrationDate, status badge, and action buttons only for status='Registered'. No XSS risk — escapeHtml wraps className and memberName.

## Check-in form with chained selection

renderTrainerCheckins (lines 305-361 in checkins.js) calls getTrainerId(), renders a form with two dropdowns: schedule and member. Schedule dropdown is populated by loadTrainerSchedulesForCheckin (lines 363-430), which fetches all schedules, filters by trainerId, and returns count. If count===0, the function replaces the form with an empty state message "Bạn chưa có lớp học nào. Vui lòng liên hệ Admin để được phân công. Sau khi có lớp học, bạn có thể thực hiện check-in cho member."

setupTrainerCheckinFormHandlers (lines 432-524) adds event listener to scheduleSelect.change → fetch `/api/Session/schedule/{scheduleId}`, filter sessions where status==='Approved', populate memberSelect with approved members. Member dropdown shows memberName with fallback. Submit button disabled until member selected.

Form submission (lines 526-558) calls POST /api/Checkin/manual with memberId and checkinTime. Backend CheckinService.CreateManualAsync (CheckinService.cs lines 73-119) validates that if userRole==='Trainer', the member must have at least one approved session in a schedule owned by the trainer (matched by email). If not, throws UnauthorizedAccessException with message "Bạn chỉ có thể check-in member trong lớp học của mình."

Error state before loading members (line 479 in checkins.js): "memberSelect.innerHTML = '<option value="">Đang tải...</option>'" clears any prior error state before fetching.

## Routing dispatch

app.js loadPage (lines 150-156) dispatches 'sessions' → renderSessions(container) and 'checkins' → renderCheckins(container). Both functions (sessions.js line 187, checkins.js line 226) check role and dispatch:
- role==='Member' → renderMemberSessions / renderMemberCheckins
- role==='Trainer' → renderTrainerSessions / renderTrainerCheckins
- else → renderAllSessions / renderAllCheckins

Trainer role has 'sessions' and 'checkins' in allowedPagesByRole (app.js line 9), so navigation works. No 403 risk.

## TrainerId lookup and cache

getTrainerId (dashboard.js lines 233-275) returns _cachedTrainerId if non-null. Otherwise, gets user.email from JWT, trims and lowercases it, fetches GET /api/Trainer?pageNumber=1&pageSize=1000, handles response.data or response.Data or [], and finds trainer where t.email.trim().toLowerCase() === userEmail. If found, caches trainerId and returns. If not found, logs error with "[getTrainerId] FAILED: No trainer found with email \"{userEmail}\". Available emails: {list}" and returns null.

logout() in auth.js (lines 47-57) calls clearTrainerIdCache() if the function exists. clearTrainerIdCache (dashboard.js lines 224-227) sets _cachedTrainerId = null and logs. This addresses the concern that cached trainerId could persist across logins.

Error messages in renderTrainerSessions (lines 500-512) and renderTrainerCheckins (lines 310-322) retrieve user.email and display "Không tìm thấy thông tin trainer cho email: {userEmail}" when trainerId is null. This gives actionable feedback to the user.

Empty state in loadTrainerSchedulesForCheckin (lines 413-424) checks if trainerSchedules.length === 0, sets select.innerHTML to "Bạn chưa có lớp nào", then replaces the entire form container with an empty-state div showing the icon and message. This prevents UI breakage for trainers with zero schedules.

## Status values and API response handling

Sessions table (lines 621-678) handles status badges: 'Registered' → badge-warning, 'Approved' → badge-success, 'Cancelled' → badge-danger, 'Attended' → badge-info, else badge-secondary. Action buttons only rendered when status==='Registered'. No undefined status values cause render issues.

API response handling (lines 556-569 in sessions.js, lines 395-410 in checkins.js) checks Array.isArray(response), response.data, response.Data, response.items. Logs each branch for debugging. Falls back to empty array if none match. This handles PagedResult<T> and plain array responses without breaking.

Console logs throughout (sessions.js lines 497, 561-569, 577, 712, 740; checkins.js lines 306, 368, 373, 470, 536) provide detailed debugging output prefixed with [TRAINER SESSIONS] or [TRAINER CHECKINS]. No sensitive data logged (memberIds and scheduleIds are logged, but no passwords or tokens).

## Vietnamese UI text

All user-facing text is in Vietnamese: "Quản Lý Đăng Ký - Huấn Luyện Viên", "Chờ duyệt", "Duyệt", "Từ chối", "Chọn lớp học", "Chọn member", "Check-in Thủ Công", "Thực Hiện Check-in", "Check-in Hôm Nay". Error messages: "Không tìm thấy thông tin trainer", "Lỗi tải danh sách lớp", "Member đã check-in hôm nay rồi", "Bạn chỉ có thể check-in member trong lớp học của mình" (from backend). Success toasts: "✅ Đã duyệt!", "✅ Đã từ chối!", "✅ Check-in thành công!". Consistent with existing Member and Admin modules.

</details>

<details>
<summary>File map</summary>

- **wwwroot/js/sessions.js** — Added renderTrainerSessions (line 495), loadTrainerSessions (line 560), renderTrainerSessionsTable (line 612), approveTrainerSession (line 709), rejectTrainerSession (line 738), filterTrainerSessions (line 545)
- **wwwroot/js/checkins.js** — Added renderTrainerCheckins (line 305), loadTrainerSchedulesForCheckin (line 363), setupTrainerCheckinFormHandlers (line 432), submitTrainerCheckin (line 526), resetTrainerCheckinForm (line 560), loadTrainerTodayCheckins (line 574)
- **wwwroot/js/app.js** — Trainer role in allowedPagesByRole includes 'sessions' and 'checkins' (line 9); renderSessions and renderCheckins dispatch correctly (lines 150-156)
- **wwwroot/js/dashboard.js** — getTrainerId implementation (line 233), clearTrainerIdCache (line 224), renderTrainerDashboard (line 277)
- **wwwroot/js/auth.js** — logout() calls clearTrainerIdCache() (line 52)
- **Controllers/SessionController.cs** — Update and UpdateStatus methods pass role and email to service (lines 51-54, 71-74)
- **Service/BUS/Implementations/SessionService.cs** — UpdateAsync validates trainer ownership (lines 192-219)
- **Controllers/CheckinController.cs** — CreateManual passes role and email to service (lines 49-50)
- **Service/BUS/Implementations/CheckinService.cs** — CreateManualAsync validates trainer can only check-in members in their schedules (lines 73-119)

See commits: 11e0ee8 (feat: add trainer-specific sessions and checkins views), 763639e (fix: add security validation for trainer session approval and check-in), 34d38bd (fix: improve trainer error messages and empty state handling)

</details>
