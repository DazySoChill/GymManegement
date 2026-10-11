# Implementation Plan: Fix 6 Member-Facing Frontend Bugs

## Overview
This plan fixes 6 bugs in the member-facing pages of the Gym Management SPA. All changes are in `wwwroot/js/*.js` and `wwwroot/index.html`. No backend changes required.

---

## BUG 1: Dashboard - `isAdmin is not defined`

- [ ] 1. Add `isAdmin()` helper function to `wwwroot/js/auth.js`.
      The function is called in dashboard.js line 8 but doesn't exist in auth.js.
      Add after getRole() function: `function isAdmin() { return getRole() === 'Admin'; }`
      Files: wwwroot/js/auth.js
      Verify: Login as admin/password, open browser console, navigate to dashboard - no error 'isAdmin is not defined'. Dashboard loads with admin stats cards visible.

---

## BUG 2: Gói Tập (Memberships) - Cancel confirmation UI + Forbidden error

- [ ] 2. Fix memberships cancel API call missing Authorization header.
      In `wwwroot/js/memberships.js` executeCancelMembership() function (around line 550-580), the apiFetch call for cancel is missing the Authorization header.
      Current: `await apiFetch(\`/api/Membership/${membershipId}/cancel\`, { method: 'POST' })`
      Change to: `await apiFetch(\`/api/Membership/${membershipId}/cancel\`, { method: 'POST', headers: { 'Authorization': 'Bearer ' + getToken() } })`
      Note: The confirmation modal with "Xác Nhận" text input already exists and works correctly (lines 530-565).
      Files: wwwroot/js/memberships.js
      Verify: Login as member01/password, go to Gói Tập, click Hủy Gói on active membership, type "Xác Nhận" in input, click red button - should succeed with toast "Hủy gói tập thành công!" without 403 Forbidden error.

---

## BUG 3: Lịch Class → Rename to "Đặt Lịch Tập"

- [ ] 3. Change sidebar navigation title for schedules page from "Lịch Class" to "Đặt Lịch Tập".
      In `wwwroot/js/app.js`, line ~11 in pageMetadata object, find the 'schedules' entry.
      Current: `'schedules': { title: 'Lịch Class', icon: '📅' }`
      Change to: `'schedules': { title: 'Đặt Lịch Tập', icon: '📅' }`
      Note: The schedules.js page already handles member schedule registration to localStorage. This is just a title change.
      Files: wwwroot/js/app.js
      Verify: Login as member01/password, check sidebar navigation shows "📅 Đặt Lịch Tập" instead of "Lịch Class".

---

## BUG 4: Đăng Ký Class (Sessions) - Registration and cancel UI

- [ ] 4. Implement session registration modal for members in `wwwroot/js/sessions.js`.
      The showRegisterSessionModal() function exists but shows error "chưa được triển khai đầy đủ".
      Replace function body (around line 280-285) with:
      - Fetch available schedules: GET /api/Schedule?pageNumber=1&pageSize=100
      - Display modal with table listing: className, trainerName, startTime, endTime, "Tham Gia" button
      - On "Tham Gia" click: POST /api/Session with body { memberId: getMemberId(), scheduleId, registrationDate: new Date().toISOString(), status: 'Registered' } and headers { 'Authorization': 'Bearer ' + getToken(), 'Content-Type': 'application/json' }
      - On success: close modal, reload member sessions
      Use injectModalStyles() pattern from memberships.js for modal HTML.
      Files: wwwroot/js/sessions.js
      Verify: Login as member01/password, go to "Đăng Ký Class", click "Đăng Ký Lớp" button - modal opens with list of available schedules. Click "Tham Gia" on any schedule - session is created and appears in table with yellow "Registered" badge.

- [ ] 5. Add cancel button for registered sessions in member view.
      In `wwwroot/js/sessions.js` renderMemberSessionsTable() function (around line 220-260), add a cancel button column.
      For sessions where status === 'Registered': show red "Hủy" button that calls updateSessionStatus(sessionId, 'Cancelled').
      For status === 'Attended': show green badge "Đã duyệt", no cancel button.
      For status === 'Cancelled': show gray badge "Đã hủy", no cancel button.
      Files: wwwroot/js/sessions.js
      Verify: Member can see cancel button only on "Registered" sessions. Click cancel - status changes to "Cancelled" with red badge.

---

## BUG 5: Check-in - `Mã QR không hợp lệ` + duplicate prevention

- [ ] 6. Add duplicate check-in prevention to `wwwroot/js/checkins.js`.
      In quickCheckin() function (around line 50-80), before calling POST /api/Checkin/qr, check for existing check-in today.
      Add before showLoading():
      ```javascript
      // Check if already checked in today
      const checkins = await apiFetch(`/api/Checkin/member/${memberId}`);
      const today = new Date().toISOString().split('T')[0];
      const todayCheckin = checkins.find(c => {
          const checkinDate = new Date(c.checkinTime).toISOString().split('T')[0];
          return checkinDate === today && !c.checkoutTime;
      });
      if (todayCheckin) {
          showError('Đã check-in hôm nay');
          return;
      }
      ```
      Note: The QR code generation in quickCheckin() already works correctly with `MEMBER_${memberId}_${Date.now()}` format.
      Files: wwwroot/js/checkins.js
      Verify: Login as member01/password, go to Check-in page, click "Check In" once (success toast). Click "Check In" again immediately - should show error "Đã check-in hôm nay" without calling API.

---

## BUG 6: Lịch Tập Của Tôi - `renderMemberSchedule is not defined`

- [ ] 7. Add member-schedule.js script tag to index.html.
      The file wwwroot/js/member-schedule.js exists and exports renderMemberSchedule(container) but is not loaded in index.html.
      In `wwwroot/index.html`, around line 85-95 in the script loading section, add:
      `<script src="js/member-schedule.js"></script>`
      Insert it after `<script src="js/users.js"></script>` and before `<script src="js/profile.js"></script>`.
      Files: wwwroot/index.html
      Verify: Login as member01/password, navigate to "Lịch Tập Của Tôi" - page loads without console error "renderMemberSchedule is not defined".

- [ ] 8. Enhance member-schedule page to show combined calendar of personal schedules and registered sessions.
      In `wwwroot/js/member-schedule.js` renderMemberSchedule() function (line 10-65):
      Current implementation only shows personal schedule preferences from MemberSchedulePreference.
      Add second data source: fetch registered sessions via GET /api/Session/member/${memberId}.
      For each session with status 'Registered' or 'Attended', fetch its schedule via GET /api/Schedule/${session.scheduleId} to get day of week and time.
      Modify the calendar display in loadSchedules() function (line 67-140) to combine:
      (a) Personal schedule preferences grouped by dayOfWeek (existing)
      (b) Registered sessions grouped by schedule.startTime day of week (new)
      Each day group should show both types with distinct styling:
      - Personal preferences: blue background, label "Lịch cá nhân"
      - Registered sessions: yellow/green background depending on status, show className, trainerName, status badge
      Files: wwwroot/js/member-schedule.js
      Verify: Login as member01/password, go to "Lịch Tập Của Tôi" - page displays weekly calendar grouped by day (Thứ 2, Thứ 3, etc.). Each day shows both personal schedule preferences (if any) and registered class sessions (if any) with distinct labels and styling.

---

## Integration Verification

After all steps, run full integration test:

1. Start backend: `cd 'd:\Workspace\Độ án 2\GymManegement\GymManegement' && dotnet run`
2. Open http://localhost:5250 in browser
3. Test all 6 bugs:
   - Login as admin/password → Dashboard loads, no console errors ✓
   - Login as member01/password → Navigate each page:
     - Dashboard: loads without error ✓
     - Gói Tập: Can cancel membership with "Xác Nhận" confirmation ✓
     - Sidebar shows "Đặt Lịch Tập" not "Lịch Class" ✓
     - Đăng Ký Class: Can register for session via modal, can cancel registered sessions ✓
     - Check-in: Can check in once, second attempt shows "Đã check-in hôm nay" error ✓
     - Lịch Tập Của Tôi: Page loads, shows combined calendar of personal schedules + registered sessions ✓

---

## Files Changed

- wwwroot/js/auth.js (add isAdmin function)
- wwwroot/js/memberships.js (fix cancel authorization header)
- wwwroot/js/app.js (rename schedules title)
- wwwroot/js/sessions.js (add registration modal, cancel button)
- wwwroot/js/checkins.js (add duplicate check)
- wwwroot/index.html (add member-schedule.js script tag)
- wwwroot/js/member-schedule.js (add combined calendar view)

---

## Notes

- All backend controllers are stable and correct - no C# changes needed
- Database must be seeded with SQL2 scripts before testing
- Test credentials: admin/password, trainer1-5/password, member01-20/password
- All API calls must include Authorization header: `'Bearer ' + getToken()`
- Maintain Vietnamese UI text throughout
- Follow existing code style: no semicolons, ES6 async/await, template literals
