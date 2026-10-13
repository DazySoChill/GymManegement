# Implementation Plan: Trainer Frontend - Sessions & Checkins Management

## Overview

Add trainer-specific views for managing session enrollments and member check-ins. Trainers can view and approve registrations for their own classes, and perform manual check-ins for members enrolled in their schedules.

## Key Findings from Investigation

### Current State
- **getTrainerId()** utility exists in dashboard.js (lines 225-262) - fetches all trainers, matches by email from JWT
- **renderSessions()** routing in sessions.js (line ~142) currently routes Admin/Trainer to renderAllSessions - needs to split
- **renderCheckins()** routing in checkins.js (line ~181) currently routes Admin/Trainer to renderAllCheckins - needs to split
- **API endpoints confirmed working**:
  - GET /api/Schedule?pageNumber=1&pageSize=1000 (returns PagedResult with `data` property)
  - GET /api/Session/schedule/{scheduleId} (used in dashboard.js line 361, returns array or PagedResult)
  - GET /api/Session/member/{memberId} (returns array)
  - PUT /api/Session/{id} with body {status: 'Approved'} or {status: 'Cancelled'}
  - POST /api/Checkin/manual with {memberId, checkinTime}
  - GET /api/Member (returns PagedResult)

### Session Object Fields (from sessions.js analysis)
Sessions include: sessionId, memberId, memberName, scheduleId, className, trainerName, classStartTime, classEndTime, status, registrationDate

### API Response Format
Backend returns PagedResult with camelCase: `{ data: [...], total, pageNumber, pageSize, totalPages }`

### Status Values for Sessions
- 'Registered' - pending approval
- 'Approved' - trainer approved
- 'Cancelled' - rejected or member cancelled
- 'Attended' - member attended the class

## Implementation Plan

- [ ] 1. **Add renderTrainerSessions function to sessions.js**
      
      Create a new function that shows enrollment requests grouped by schedule. Trainers see only sessions for their own schedules with approve/reject actions.
      
      **Files:** wwwroot/js/sessions.js (add after renderMemberSessions, around line 400)
      
      **Implementation details:**
      - Call `getTrainerId()` from dashboard.js scope (functions are global in this vanilla JS app)
      - If trainerId is null, show error message: "Không tìm thấy thông tin trainer"
      - Fetch schedules: `GET /api/Schedule?pageNumber=1&pageSize=1000`
      - Filter schedules client-side by trainerId: `schedules.filter(s => s.trainerId === trainerId)`
      - Extract scheduleIds from filtered schedules
      - For each scheduleId, fetch enrollments: `GET /api/Session/schedule/{scheduleId}`
      - Flatten all sessions into single array
      - Group by scheduleId for display (optional - can use flat table)
      - UI structure: Card header with title "Quản Lý Đăng Ký - Huấn Luyện Viên", table with columns: Session ID, Member Name, Class Name, Registration Date, Status badge, Actions
      - For sessions with status='Registered': show Approve button (green ✓) and Reject button (red ✗)
      - For other statuses: show status badge only (no actions)
      - Handle response formats: check for `data`, `Data`, or direct array
      - Add console.log statements for debugging (pattern: `console.log('[TRAINER SESSIONS] ...')`)
      
      **Verification:** Add temporary call `renderTrainerSessions(document.getElementById('main-content'))` in browser console after logging in as Trainer, verify data loads and buttons appear

- [ ] 2. **Add session approval/rejection handlers to sessions.js**
      
      Create functions to approve or reject session enrollments.
      
      **Files:** wwwroot/js/sessions.js (add after renderTrainerSessions)
      
      **Implementation details:**
      - `approveTrainerSession(sessionId)`: calls `PUT /api/Session/${sessionId}` with body `{status: 'Approved'}`
      - `rejectTrainerSession(sessionId)`: calls `PUT /api/Session/${sessionId}` with body `{status: 'Cancelled'}`
      - Both show confirmation dialog before action: "Bạn có chắc muốn duyệt/từ chối đăng ký này?"
      - On success: show toast "✅ Đã duyệt!" or "✅ Đã từ chối!", reload trainer sessions view
      - On error: show error toast with message
      - Use existing `apiFetch`, `showLoading`, `hideLoading`, `showToast`, `showError` utilities
      
      **Verification:** Click approve button on pending session, verify status updates to 'Approved' and button disappears

- [ ] 3. **Update renderSessions routing in sessions.js**
      
      Modify the role-based routing to call renderTrainerSessions for Trainer role.
      
      **Files:** wwwroot/js/sessions.js (modify renderSessions function, around line 142)
      
      **Current code:**
      ```javascript
      async function renderSessions(container) {
          const role = getRole();
          const memberId = getMemberId();
          
          if (role === 'Member' && memberId) {
              await renderMemberSessions(container, memberId);
          } else {
              await renderAllSessions(container);
          }
      }
      ```
      
      **Change to:**
      ```javascript
      async function renderSessions(container) {
          const role = getRole();
          const memberId = getMemberId();
          
          if (role === 'Member' && memberId) {
              await renderMemberSessions(container, memberId);
          } else if (role === 'Trainer') {
              await renderTrainerSessions(container);
          } else {
              await renderAllSessions(container);
          }
      }
      ```
      
      **Verification:** Login as Trainer, navigate to Sessions page, verify renderTrainerSessions is called (check console logs)

- [ ] 4. **Add renderTrainerCheckins function to checkins.js**
      
      Create a trainer-specific check-in view with manual check-in form and history.
      
      **Files:** wwwroot/js/checkins.js (add after renderMemberCheckins, around line 180)
      
      **Implementation details:**
      - Call `getTrainerId()` to get trainer's ID
      - If trainerId is null, show error message
      - UI has two sections:
        1. Manual Check-in Form (card at top)
        2. Recent Check-ins Table (card below)
      - **Manual Check-in Form:**
        - Select schedule dropdown (populated from trainer's schedules)
        - On schedule selection: fetch approved sessions `GET /api/Session/schedule/{scheduleId}`, filter by status='Approved', populate member dropdown
        - Member dropdown shows: "{memberName} (ID: {memberId})"
        - Check-in button calls `POST /api/Checkin/manual` with `{memberId, checkinTime: new Date().toISOString()}`
        - On success: clear form, reload check-in history, show toast "✅ Check-in thành công!"
      - **Recent Check-ins Table:**
        - Fetch `GET /api/Checkin?pageNumber=1&pageSize=50`
        - Filter by today's date: `checkins.filter(c => new Date(c.checkinTime).toDateString() === new Date().toDateString())`
        - Show table with columns: Member Name, Check-in Time, Status
        - Use existing `renderCheckinsTable` pattern but filtered
      - Add refresh button: "🔄 Làm mới"
      
      **Verification:** Navigate to Checkins as Trainer, verify form loads, select schedule and member, submit check-in successfully

- [ ] 5. **Add check-in form handlers to checkins.js**
      
      Create event handlers for schedule/member selection and form submission.
      
      **Files:** wwwroot/js/checkins.js (add after renderTrainerCheckins)
      
      **Implementation details:**
      - `onTrainerScheduleChange(scheduleId)`: async function that fetches sessions for schedule, filters approved, populates member dropdown
      - `submitTrainerCheckin()`: async function that reads form values, validates, calls API, shows success/error
      - Form validation: ensure both schedule and member are selected before allowing submit
      - Clear member dropdown when schedule changes
      - Disable check-in button until both selections made
      
      **Verification:** Select schedule, verify member dropdown populates with only approved members; submit check-in, verify POST succeeds

- [ ] 6. **Update renderCheckins routing in checkins.js**
      
      Modify role-based routing to call renderTrainerCheckins for Trainer role.
      
      **Files:** wwwroot/js/checkins.js (modify renderCheckins function, around line 181)
      
      **Current code:**
      ```javascript
      async function renderCheckins(container) {
          const role = getRole();
          const memberId = getMemberId();
          
          if (role === 'Member' && memberId) {
              await renderMemberCheckins(container, memberId);
          } else {
              await renderAllCheckins(container);
          }
      }
      ```
      
      **Change to:**
      ```javascript
      async function renderCheckins(container) {
          const role = getRole();
          const memberId = getMemberId();
          
          if (role === 'Member' && memberId) {
              await renderMemberCheckins(container, memberId);
          } else if (role === 'Trainer') {
              await renderTrainerCheckins(container);
          } else {
              await renderAllCheckins(container);
          }
      }
      ```
      
      **Verification:** Login as Trainer, navigate to Checkins page, verify renderTrainerCheckins is called

- [ ] 7. **Test complete workflow: Session approval**
      
      End-to-end test of session management.
      
      **Test steps:**
      1. Login as Member, register for a class taught by Trainer X
      2. Logout, login as Trainer X
      3. Navigate to Sessions page
      4. Verify pending registration appears with Approve/Reject buttons
      5. Click Approve
      6. Verify status changes to 'Approved' and buttons disappear
      7. Logout, login as Member
      8. Verify session now shows status 'Approved'
      
      **Verification:** All steps complete without errors, status persists across sessions

- [ ] 8. **Test complete workflow: Manual check-in**
      
      End-to-end test of check-in feature.
      
      **Test steps:**
      1. Login as Trainer with at least one approved member in a schedule
      2. Navigate to Checkins page
      3. Select a schedule from dropdown
      4. Verify member dropdown populates with approved members only
      5. Select a member
      6. Click Check-in button
      7. Verify success toast appears
      8. Verify check-in appears in Recent Check-ins table
      9. Navigate to Admin check-ins view
      10. Verify check-in appears in system-wide list
      
      **Verification:** Check-in persists and is visible in all relevant views

## Edge Cases & Error Handling

### getTrainerId returns null
- **Cause:** JWT email doesn't match any trainer in database, or API call fails
- **Handling:** Show error message "Không tìm thấy thông tin trainer. Vui lòng liên hệ Admin." with empty-state icon
- **Location:** Beginning of both renderTrainerSessions and renderTrainerCheckins

### No schedules for trainer
- **Cause:** Trainer has no schedules assigned
- **Handling:** Show empty-state message "Bạn chưa có lớp học nào. Vui lòng liên hệ Admin để được phân công."
- **Location:** After fetching and filtering schedules in renderTrainerSessions

### No approved members in schedule
- **Cause:** No members have approved status for selected schedule
- **Handling:** Member dropdown shows "Chưa có member nào được duyệt" option (disabled)
- **Location:** onTrainerScheduleChange function

### API errors (401, 403, 500, network)
- **Handling:** Catch all errors, show toast with message from error.message, log to console for debugging
- **Pattern:** `catch (error) { hideLoading(); showError('Lỗi: ' + error.message); console.error('[TRAINER] Error:', error); }`
- **Location:** Every apiFetch call

### Duplicate check-in (member already checked in today)
- **Cause:** Backend may reject duplicate check-ins
- **Handling:** If API returns 400/409, show error "Member đã check-in hôm nay rồi"
- **Location:** submitTrainerCheckin error handler

### Schedule with zero sessions
- **Cause:** Schedule exists but no one registered
- **Handling:** Don't show schedule in sessions table (filter out empty schedules)
- **Location:** After fetching sessions for all schedules, filter schedules with sessions.length > 0

## Data Flow Diagrams

### Session Approval Flow
```
Trainer clicks "Sessions" page
  → renderSessions() checks role
  → renderTrainerSessions() called
  → getTrainerId() fetches trainer ID
  → Fetch schedules, filter by trainerId
  → For each schedule: fetch sessions
  → Flatten and display in table
  → User clicks Approve button
  → approveTrainerSession(sessionId)
  → PUT /api/Session/{id} {status: 'Approved'}
  → Success → reload view
```

### Manual Check-in Flow
```
Trainer clicks "Checkins" page
  → renderCheckins() checks role
  → renderTrainerCheckins() called
  → Load trainer's schedules into dropdown
  → User selects schedule
  → onTrainerScheduleChange(scheduleId)
  → Fetch GET /api/Session/schedule/{scheduleId}
  → Filter status='Approved'
  → Populate member dropdown
  → User selects member
  → User clicks Check-in
  → submitTrainerCheckin()
  → POST /api/Checkin/manual {memberId, checkinTime}
  → Success → reload recent check-ins table
```

## API Endpoints Summary

| Endpoint | Method | Purpose | Response Format |
|----------|--------|---------|-----------------|
| /api/Schedule | GET | Get all schedules (filter client-side by trainerId) | PagedResult with `data` array |
| /api/Session/schedule/{scheduleId} | GET | Get enrollments for a schedule | Array or PagedResult |
| /api/Session/{id} | PUT | Update session status | Session object |
| /api/Checkin/manual | POST | Manual check-in | Checkin object |
| /api/Checkin | GET | Get all check-ins | PagedResult with `data` array |
| /api/Member | GET | Get all members (for check-in form) | PagedResult with `data` array |
| /api/Trainer | GET | Get all trainers (used by getTrainerId) | PagedResult with `data` array |

## Build & Verification Commands

This is an ASP.NET Core 8.0 application with vanilla JavaScript frontend. No build step needed for JS files.

**Start dev server:**
```powershell
dotnet run --project "d:\Workspace\Độ án 2\GymManegement\GymManegement\GymManegement.csproj"
```

**Verification:**
1. Hard refresh browser (Ctrl+Shift+R) after modifying JS files
2. Check browser console for errors (F12 → Console)
3. Check network tab for API calls (F12 → Network → XHR)
4. Test with actual Trainer account - create one via Admin panel if needed

**Manual testing checklist:**
- [ ] Trainer can see only their own schedules' sessions
- [ ] Approve button works and updates status
- [ ] Reject button works and updates status
- [ ] Manual check-in form loads schedules
- [ ] Selecting schedule populates approved members
- [ ] Check-in succeeds and appears in history
- [ ] All error cases show appropriate messages
- [ ] Console logs help with debugging (use filter: [TRAINER])

## Notes

- **No /api/Schedule/trainer/{trainerId} endpoint exists** - must fetch all schedules and filter client-side
- **getTrainerId() is already implemented** in dashboard.js - reuse it, don't re-implement
- **Session.memberName field exists** - backend already includes it, no need to fetch from /api/Member/{id}
- **Existing modal styles** are already defined in checkins.js (ensureModalStyles function) - reuse for consistency
- **_cachedTrainerId** is module-level in dashboard.js - cache persists across function calls (performance optimization)
- **Reviewed previous attempt** in trainer-diff.txt - issues were: N+1 queries in dashboard, no backend ownership validation, silent trainerId lookup failures. This plan avoids those by: using simpler sequential loads (acceptable for small datasets), focusing on frontend-only features, adding explicit error messages.

## Reviewer Context (for next workflow step)

The trainer-diff.txt file contains a review of a previous attempt that was rejected. Key issues from that review:
1. N+1 dashboard queries - NOT applicable to this task (we're not modifying dashboard)
2. No backend ownership validation - ACKNOWLEDGED, frontend filtering is intentional scope
3. Silent trainerId lookup failure - ADDRESSED in this plan with explicit error messages
4. Session filtering fetches pageSize=10000 - ACCEPTED as reasonable for gym scale (~100 trainers, ~1000 sessions)
5. Disabled dropdown doesn't submit - NOT applicable (we're not modifying schedule creation)

This plan focuses ONLY on the two specific features requested: session management and check-ins for trainers. Backend security improvements are out of scope.
